extends SceneTree
var checks=0
var failures=0
var g:Node
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",message)
func run():
	Catalog.load_all()
	var geometry=Node3D.new();root.add_child(geometry)
	for x in [0.,2.]:
		var mesh=MeshInstance3D.new();var box=BoxMesh.new();box.size=Vector3(4,1,4);mesh.mesh=box;mesh.material_override=StandardMaterial3D.new();geometry.add_child(mesh);mesh.position=Vector3(x,.5,0)
	SurfaceCleanup.clean(geometry);var top_area=0.
	for mesh in geometry.get_children():
		var arrays=mesh.mesh.surface_get_arrays(0);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL]
		for i in range(0,vertices.size(),3):
			if normals[i].y>.9:top_area+=(vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).length()*.5
	expect(is_equal_approx(top_area,24.),"coplanar overlapping floors render their union exactly once")
	geometry.free()
	var defaults=Rules.default_options();expect(defaults.map==13 and defaults.max_players==8,"default room is an eight-player map")
	for index in range(19):
		var opts=Rules.default_options();opts.map=index;opts.max_players=32;opts.bots=31;Rules.sanitize_room(opts)
		expect(opts.max_players<=Rules.MAP_PLAYERS[opts.map] and opts.bots<opts.max_players,"server selects a map that supports the requested capacity "+str(index))
	for id in Catalog.weapons:
		var w=Catalog.get_weapon(id)
		if w.kind!="gun":continue
		var previous=float(w.damage)
		for distance in [0.,5.,10.,20.,40.,80.,160.,301.]:
			var current=CombatBalance.damage_at(w,distance)
			expect(current<=previous+.001 and current>=0.,id+" monotonic falloff at "+str(distance));previous=current
		expect(CombatBalance.damage_at(w,5.,"head")>CombatBalance.damage_at(w,5.,"torso") and CombatBalance.damage_at(w,5.,"legs")<CombatBalance.damage_at(w,5.,"torso"),id+" zone multipliers")
	expect(Catalog.get_weapon("r2").interval>=2. and Catalog.get_weapon("r1").interval>=1.3,"snipers cannot fire at DMR cadence")
	expect(Catalog.get_weapon("r2").ads_speed<2. and Catalog.get_weapon("r3").ads_speed<3.,"scoped movement penalty")
	for id in ["e1","e2","e3"]:
		var w=Catalog.get_weapon(id);var radius=0.
		for i in range(int(w.pellets)):
			var sample=CombatBalance.pellet_sample(i,int(w.pellets),.31);radius+=sqrt(sample.x)
		expect(radius/w.pellets>.62 and w.ads_spread>=3.8,id+" pellets occupy a broad cone")
		expect(CombatBalance.damage_at(w,25.)*w.pellets<15.,id+" long-range shotgun damage limited")
	var audit=[]
	for index in range(19):
		var a=Arena.new();root.add_child(a);a.build(index);await physics_frame;await physics_frame
		expect(a.indoors==(index in CombatLayout.INDOOR),"indoor selection "+str(index))
		if a.indoors:
			var hit=a.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,9.,0),Vector3(0,12.,0),1))
			expect(not hit.is_empty(),"indoor map has solid ceiling "+str(index))
		var distances=[]
		for x in range(-4,5):
			for z in range(-4,5):
				var pos=Vector3(x*a.bounds.x*.17,1.5,z*a.bounds.y*.17)
				if not a.point_clear(pos-Vector3.UP*1.5) or absf(a.walk_height(pos-Vector3.UP*1.5))>.5:continue
				for angle in range(8):
					var dir=Vector3(cos(angle*TAU/8.),0,sin(angle*TAU/8.));var hit=a.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos,pos+dir*250.,1))
					distances.append(pos.distance_to(hit.position) if not hit.is_empty() else 250.)
		distances.sort();var long_lines=distances.filter(func(d):return d>50.).size()
		audit.append({"map":index,"indoor":a.indoors,"night":a.get_meta("night"),"blockers":a.get_meta("sight_blockers"),"removed_faces":a.architecture.get_meta("coplanar_faces_removed",0),"rays":distances.size(),"over_50m":long_lines,"median":distances[distances.size()/2] if not distances.is_empty() else 0})
		print("MAP_AUDIT ",JSON.stringify(audit.back()));a.free();await process_frame
	DirAccess.make_dir_recursive_absolute("res://../validation");FileAccess.open("res://../validation/v102-map-audit.json",FileAccess.WRITE).store_string(JSON.stringify(audit,"  "))
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.options.map_random=false;g.options.map=13;g.build_world();g.phase="lobby";g.add_player(1,"TEST","test_v102_local");g.phase="combat";g.clock=100.
	var p=g.players[1];var actor=g.actors[1];actor.position=Vector3(0,.05,g.arena.bounds.y-7);actor.reset_view(0);p.protect=0.;p.role=0;p.gadget=1;p.slot=2;p.gadget_count=1
	expect(GrenadeLogic.begin(g,1),"grenade cooking begins")
	g.process_trigger(1);expect(p.cooking>0 and g.grenades[0].held,"G cooking is not released by an idle mouse")
	var deadline=g.grenades[0].until;g.clock+=1.;GrenadeLogic.release(g,1)
	expect(not g.grenades[0].held and g.grenades[0].until==deadline,"release retains original fuse")
	GrenadeLogic.tick(g,.1);expect(g.grenades.size()==1,"grenade does not explode on release")
	g.grenades.clear();p.gadget_count=1;p.gadget_ready=0.;p.hp=100.;p.armor=0.
	expect(GrenadeLogic.begin(g,1),"second cooking fixture begins")
	g.clock+=3.1;GrenadeLogic.tick(g,.016);expect(g.grenades.is_empty() and p.hp<100.,"overcooking damages the holder and consumes grenade")
	g.spawn(1);p.protect=0.;p.slot=0;p.primary="r2";p.fire_ready=0.;p.switch_until=0.;g.equip_ammo(p);var mag=p.mag.r2
	g.fire(1);g.clock+=.1;g.fire(1);expect(p.mag.r2==mag-1,"server blocks rapid sniper firing")
	g.add_player(2,"TARGET","target_v102");g.spawn(2);var target=g.players[2];target.team=1-p.team;target.protect=0.;target.armor=0.;target.hp=100.;g.actors[2].position=Vector3(0,20,-5)
	actor.position=Vector3(0,20,0);actor.reset_view(0);actor.spread_angle=0.;p.primary="a1";p.fire_ready=0.;p.spray_phase=0.;p.bloom=0.;p.reload=0.;g.equip_ammo(p)
	var cover=g.arena.box(Vector3(0,20.75,-.3),Vector3(3,1.5,.3),Color.GRAY)
	await physics_frame;await physics_frame
	expect(g.ray(actor.eye(),g.actors[2].eye(),[actor.get_rid()],1).is_empty(),"camera can see above fixture cover")
	g.fire(1);expect(target.hp==100. and p.mag.a1==29,"covered muzzle cannot fire through camera-visible target")
	cover.queue_free();await physics_frame;await physics_frame;p.fire_ready=0.;p.spray_phase=0.;p.bloom=0.;g.fire(1)
	expect(target.hp<100.,"unobstructed muzzle reaches target")
	g.disconnected(2)
	actor.position=Vector3(0,.1,g.arena.bounds.y-7);actor.input_state.fire=false;actor.input_state.sprint=false;actor.input_state.x=0.;actor.input_state.z=0.
	for i in range(30):actor.simulate(.016,g.clock,false);await physics_frame
	actor.velocity=Vector3(0,0,-7.);p.slide_ready=0.
	expect(g.begin_slide(1),"double-shift command starts grounded moving slide")
	expect(not g.begin_slide(1),"slide cooldown blocks repeat")
	actor.position.y+=5.;actor.velocity=Vector3.UP;actor.move_and_slide();p.slide_ready=0.
	expect(not g.begin_slide(1),"airborne slide rejected")
	var fx=CombatFX.new();g.add_child(fx);var body=PhysicsRagdoll.new();fx.add_child(body);body.build(null,Vector3(0,6.,g.arena.bounds.y-7),Vector3.FORWARD,0,0,0.,false,Vector3.ZERO)
	var initial=body.bodies[0].position.y
	for i in range(150):await physics_frame
	expect(body.bodies[0].position.y<initial-3. and body.bodies[0].position.y>-.8,"airborne ragdoll falls onto ground")
	g.leave_game();g.free();await process_frame
	print("V102_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
