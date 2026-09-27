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
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
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
		expect(data.faces.size()<=27000,"native anatomical triangle budget remains below 27k")
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
