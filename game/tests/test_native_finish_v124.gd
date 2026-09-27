extends SceneTree
var checks=0
var failures=0
class FailedNavigation extends BotNavigation:
	var calls=0
	func route(_from:Vector3,_to:Vector3) -> PackedVector3Array:
		calls+=1;return PackedVector3Array()
class NavigationFixture extends Node:
	var actors={}
	var clock=0.
	var bot_navigation=FailedNavigation.new()
class HudFixture extends Node:
	var players={}
	var local_id=1
	var options={"infinite":false}
	var clock=0.
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	for role in HumanModel.FEMALE_ROLES:
		var crown=OperatorHair.point(0.,1.,role,false)
		expect(crown.y<.15 and crown.y>.12,"native hair crown fits authored skull rather than oversized cap")
		var rig=CartoonModel.build(role,0);root.add_child(rig)
		var head=rig.get_node("Hips/Chest/Head");var painted=false
		for mesh in head.find_children("*","MeshInstance3D",true,false):
			if mesh.material_override is ShaderMaterial:
				var colors=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
				if colors!=null and colors.size()>0:
					var dark=false;var skin=false
					for color in colors:dark=dark or color.r<.1;skin=skin or color.r>.2
					painted=dark and skin
		expect(painted,"web hairline shares the original head surface with preserved skin/hair colors")
		rig.free()
	var hud_game=HudFixture.new();root.add_child(hud_game)
	var p={"primary":"a1","secondary":"pistol","slot":0,"mag":{"a1":30,"pistol":12},"reserve":{"a1":90},"reload":0.,"energy":180}
	hud_game.players[1]=p;var pips=AmmoPips.new();pips.game=hud_game
	expect(pips.refresh_state() and not pips.refresh_state(),"unchanged ammunition retains existing draw geometry")
	hud_game.clock=1.;expect(not pips.refresh_state(),"simulation time alone does not rebuild ammo polygons")
	p.mag.a1-=1;expect(pips.refresh_state(),"firing redraws the removed round")
	p.reload=3.;expect(pips.refresh_state(),"reload starts hiding ammunition")
	hud_game.clock=4.;expect(pips.refresh_state(),"reload completion restores ammunition")
	p.slot=1;expect(pips.refresh_state(),"switching guns refreshes the magazine")
	p.slot=2;expect(pips.refresh_state(),"equipping a gadget clears ammunition")
	p.energy=120;expect(pips.refresh_state(),"healing energy updates its bar")
	hud_game.players.clear();expect(pips.refresh_state(),"leaving the match invalidates cached ammunition")
	pips.free();hud_game.free()
	var duet=WeaponVisual.new();root.add_child(duet);duet.build(Catalog.get_weapon("dual_pistols"))
	expect(duet.dual_guns[0].position.x-duet.dual_guns[1].position.x>=.59,"first-person DUET leaves a clear center gap")
	duet.animate_reload(.4,.5,.02)
	expect(duet.dual_guns[0].position.x-duet.dual_guns[1].position.x>=.59,"DUET reload preserves widened hand spacing")
	duet.free()
	var max_diagonal=0.
	for index in range(Rules.MAPS.size()):
		var extent=DefusalLayout.spec(index).size if DefusalLayout.enabled(index) else Vector2(44,48) if index==PracticeLayout.INDEX else MapLayouts.extent(index)
		max_diagonal=maxf(max_diagonal,extent.length()*2.)
	var longest_lifetime=RocketCombat.flight_lifetime(Vector2.ONE*(max_diagonal/sqrt(2.)*.5))
	expect(RocketCombat.SPEED*longest_lifetime>=max_diagonal*1.2,"rocket lifespan spans every map with at least 20 percent range margin")
	expect(RocketCombat.flight_lifetime(Vector2(50,50))==10.,"small maps retain ten-second rocket expiry")
	print("ROCKET_RANGE diagonal=",max_diagonal," lifetime_distance=",RocketCombat.SPEED*longest_lifetime)
	for web in [false,true]:
		ProjectSettings.set_setting("application/config/web_assets",web)
		for item in [[1,0],[4,0],[4,1],[5,0],[0,8],[0,9]]:
			var a=Node3D.new();var b=Node3D.new();root.add_child(a);root.add_child(b)
			EquipmentPreview.gadget_model(a,item[0],item[1]);EquipmentPreview.gadget_model(b,item[0],item[1])
			var meshes=a.find_children("*","MeshInstance3D",true,false);var copies=b.find_children("*","MeshInstance3D",true,false)
			expect(meshes.size()==1 and copies.size()==1,"small held gadget stays one merged draw mesh")
			expect(meshes[0].mesh==copies[0].mesh,"held gadgets reuse cached immutable geometry")
			expect(a.find_children("*","Light3D",true,false).is_empty(),"held gadgets add no dynamic lights")
			a.free();b.free()
	ProjectSettings.set_setting("application/config/web_assets",false)
	expect(EquipmentPreview.gadget_templates.size()<=80,"gadget scene cache remains bounded")
	var fixture=NavigationFixture.new();root.add_child(fixture)
	var actor=Node3D.new();fixture.add_child(actor);fixture.actors[-1]=actor
	var brain=BotAgent.new();brain.game=fixture;brain.id=-1
	for i in range(120):fixture.clock=i/60.;brain.navigate(Vector3(30,0,0),1./60.)
	expect(fixture.bot_navigation.calls>=4 and fixture.bot_navigation.calls<=6,"unreachable routes retry at bounded intervals instead of every tick")
	var nav=BotNavigation.new()
	expect(nav.request_route(1.) and nav.request_route(1.) and not nav.request_route(1.),"simultaneous path queries have a per-tick budget")
	expect(nav.request_route(1.+1./60.),"pending bots can request a path on the next simulation tick")
	fixture.free()
	CombatFX.prepare_devices()
	expect(CombatFX.device_templates.size()==4,"all deployment assemblies load from baked assets")
	var edge_builds=Construction.edge_builds
	for kind in ["turret","cover"]:
		for team in range(2):
			var a=Node3D.new();var b=Node3D.new();root.add_child(a);root.add_child(b)
			CombatFX.device(a,kind,team);CombatFX.device(b,kind,team)
			var meshes=a.find_children("*","MeshInstance3D",true,false)
			var copies=b.find_children("*","MeshInstance3D",true,false)
			expect(not meshes.is_empty() and meshes.size()==copies.size(),"deployment retains its baked parts")
			for i in range(meshes.size()):
				expect(meshes[i].mesh==copies[i].mesh,"deployment instances share immutable GPU geometry")
				expect(meshes[i].get_meta("construction_wire",null) is ArrayMesh,"construction edge extraction is baked offline")
				Construction.add_edges(meshes[i],team)
			if kind=="turret":
				a.get_node("TurretHead").rotation.y=1.
				expect(b.get_node("TurretHead").rotation.y==0.,"shared turret geometry preserves independent aiming")
			a.free();b.free()
	expect(Construction.edge_builds==edge_builds,"spawning all deployment types never scans triangle adjacency")
	var viewport=SubViewport.new();root.add_child(viewport);GraphicsOptions.detail=0;GraphicsOptions.antialias=0;GraphicsOptions.apply_viewport(viewport)
	expect(viewport.mesh_lod_threshold==2.5 and viewport.scaling_3d_scale==1. and viewport.msaa_3d==Viewport.MSAA_DISABLED,"low quality reduces distant geometry without changing resolution")
	var scenery=Node3D.new();root.add_child(scenery);var wall=MeshFactory.box(scenery,Vector3.ZERO,Vector3.ONE,Color.WHITE);wall.material_override=SurfaceFinish.world_material()
	GraphicsOptions.apply_world(scenery);expect(wall.material_override.get_shader_parameter("texture_detail")==false,"low world shader skips texture detail")
	GraphicsOptions.detail=1;GraphicsOptions.apply_world(scenery);expect(wall.material_override.get_shader_parameter("texture_detail")==true,"medium world shader restores texture detail")
	scenery.free();viewport.free()
	var male_texture=SurfaceFinish.human_material(0).get_shader_parameter("anatomy_detail")
	expect(male_texture==SurfaceFinish.human_material(2).get_shader_parameter("anatomy_detail"),"male roles share one detail texture")
	var female_texture=SurfaceFinish.human_material(1).get_shader_parameter("anatomy_detail")
	expect(female_texture==SurfaceFinish.human_material(5).get_shader_parameter("anatomy_detail"),"female roles share one detail texture")
	for role in [0,1,5]:
		var data=AuthoredHuman.source(role);var crossed=0
		for face in data.faces:
			var lo=INF;var hi=-INF
			for index in face:lo=minf(lo,data.vertices[index][1]);hi=maxf(hi,data.vertices[index][1])
			if lo<1.47999 and hi>1.48001:crossed+=1
		expect(crossed==0,"skin and shirt have a real cut neckline, role "+str(role))
		expect(data.faces.size()<=27200,"neck and waist seams add fewer than 1.5 percent native triangles")
		var crossed_waist=0
		for face in data.faces:
			var lo=INF;var hi=-INF;var torso=true
			for index in face:
				lo=minf(lo,data.vertices[index][1]);hi=maxf(hi,data.vertices[index][1])
				for influence in data.weights[index]:
					if int(influence[0]) in [3,4,5,6,7,8] and influence[1]>.5:torso=false
			if torso and lo<1.02499 and hi>1.02501:crossed_waist+=1
		expect(crossed_waist==0,"shirt and trousers do not interpolate across the waistline")
		var rig=CharacterVisual.make_rig(role,0);root.add_child(rig);OperatorSkin.install(rig,str(role)+"_finish")
		expect(rig.get_node("DeformSkeleton").get_bone_count()==15,"existing skeletal budget preserved")
		rig.free()
	var holder=Node3D.new();root.add_child(holder)
	var hand=WeaponHand.new();holder.add_child(hand);hand.build(true,false,1)
	var shared=hand.handed_mesh.get_child(0).mesh
	hand.free();var warm=HumanModel.loft_meshes.size();var elapsed=[]
	for i in range(40):
		var start=Time.get_ticks_usec();hand=WeaponHand.new();holder.add_child(hand);hand.build(i%2==0,false,1)
		expect(hand.handed_mesh.get_child(0).mesh==shared,"weapon hand geometry shared across swaps")
		hand.free();elapsed.append((Time.get_ticks_usec()-start)/1000.)
	expect(HumanModel.loft_meshes.size()==warm,"hand swaps do not grow mesh cache")
	expect(HumanModel.loft_meshes.size()<=HumanModel.LOFT_CACHE_LIMIT,"loft cache has a fixed limit")
	GraphicsOptions.physics_effects=0;var fx=CombatFX.new();holder.add_child(fx)
	for i in range(8):fx.explosion(Vector3(i,0,0))
	var first=fx.explosion_pool[0];var material=first.puffs[0].material;var nodes=fx.get_child_count()
	var memory=[]
	for cycle in range(30):
		fx.clear(true);await process_frame;await process_frame
		for i in range(8):fx.explosion(Vector3(i,0,0),cycle%2==0)
		memory.append(int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
		expect(fx.explosion_pool.size()==8 and fx.get_child_count()==nodes,"explosion pool stays bounded")
		expect(fx.explosion_pool[0]==first and first.puffs[0].material==material,"explosion meshes and materials reused")
		expect(first.puffs.size()==24 and first.puffs[0].node.mesh==first.puffs[-1].node.mesh,"fire/dust appearance retained with one shared quad")
	expect(memory[-1]<=memory[1]+2,"repeated bursts do not retain new resources")
	fx.clear();await process_frame;await process_frame
	expect(fx.get_child_count()==0 and fx.explosion_pool.is_empty(),"leaving releases retained effect pool")
	GraphicsOptions.physics_effects=2
	for i in range(12):fx.explosion(Vector3.ZERO)
	expect(BurstVisual.debris_shapes.size()<=3,"debris uses three fixed shared collision shapes")
	fx.clear();await process_frame;await process_frame
	expect(BurstVisual.debris_count==0,"all decorative rigid bodies released")
	holder.free();await process_frame
	print("NATIVE_FINISH_RESULT ",checks-failures,"/",checks," hand_swap_ms=",elapsed," burst_resource_samples=",memory)
	quit(1 if failures else 0)
