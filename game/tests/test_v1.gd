extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if ok:print("PASS ",label)
	else:failures+=1;printerr("FAIL ",label)
func run():
	Catalog.load_all()
	var g=load("res://scripts/game.gd").new();g.render_actors=true;root.add_child(g);g.set_physics_process(false);g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=7;g.build_world();g.add_player(1,"V1","height_test")
	var actor=g.actors[1]
	for role in range(6):
		g.players[1].role=role;actor.set_team(0);actor.reset_view(0)
		expect(is_equal_approx(actor.shape.shape.height,HumanModel.HEIGHTS[role]),"role %d collision follows stature"%role)
		expect(is_equal_approx(actor.eye().y-actor.position.y,actor.camera.position.y),"role %d first-person eye follows stature"%role)
		expect(is_equal_approx(actor.character.rig.scale.y,HumanModel.HEIGHTS[role]/1.8),"role %d model follows stature"%role)
		actor.input_state.crouch=true;actor.simulate(.016,0,false)
		expect(is_equal_approx(actor.shape.shape.height,HumanModel.HEIGHTS[role]*1.45/1.8),"role %d crouch capsule follows stature"%role)
	var loft=HumanModel.loft(g,Vector3.ZERO,[Vector4(-.2,.2,.1,0),Vector4(.2,.2,.1,0)],Color.WHITE)
	var arrays=loft.mesh.surface_get_arrays(0)
	expect(arrays[Mesh.ARRAY_NORMAL][0].x>0.5,"organic surface normals face outward")
	loft.free()
	for index in range(19):
		var arena=Arena.new();root.add_child(arena);arena.build(index)
		expect(arena.props.size()>=5 and arena.props.size()<=28,"map %d has bounded interactive variety (%d)"%[index,arena.props.size()])
		expect(int(arena.get_meta("dressing_count"))>=8,"map %d has added scene furniture"%index)
		for prop in arena.props.values():
			if not prop.freeze:expect(false,"non-authoritative map must freeze physics")
		var other=Arena.new();root.add_child(other);other.build(index)
		expect(arena.prop_states()==other.prop_states() and arena.obstacles==other.obstacles,"map %d dressing and prop IDs are deterministic across peers"%index)
		other.free()
		arena.free()
	# Real rigid body movement from a ray hit, including off-center torque.
	var prop=g.arena.props[0];prop.reset_home();await physics_frame;await physics_frame
	var origin=prop.global_position+Vector3(0,.20,2.)
	var hit=g.ray(origin,prop.global_position+Vector3(.15,.20,0),[],8)
	expect(not hit.is_empty() and hit.collider==prop,"weapon ray mask reaches interactive prop")
	var start=prop.global_position;var rotation_start=prop.quaternion
	if not hit.is_empty():prop.hit(hit.position,Vector3(.1,0,-1),40.)
	await create_timer(.7).timeout
	expect(prop.global_position.distance_to(start)>.08,"bullet impulse physically moves barrel")
	expect(absf(prop.quaternion.dot(rotation_start))<.9999,"off-center bullet rotates barrel")
	var replica=InteractiveProp.new();replica.configure(99,"barrel",false);replica.position=Vector3(0,4,0);root.add_child(replica)
	replica.receive(prop.global_position,prop.quaternion)
	expect(replica.global_position.distance_to(prop.global_position)<.001,"late client snaps to authoritative pose")
	var before=replica.global_position;replica.hit(before,Vector3.RIGHT,100.)
	expect(replica.linear_velocity==Vector3.ZERO,"client cannot apply authoritative impulses")
	replica.receive(Vector3(NAN,0,0),Quaternion.IDENTITY)
	expect(replica.target.origin==before,"invalid network transform is rejected")
	prop.reset_home();expect(prop.global_position.distance_to(prop.home.origin)<.001,"new round restores prop positions")
	await physics_frame;await physics_frame
	var shot_start=prop.global_position
	g.phase="combat";g.clock=20.;g.players[1].protect=0.;g.players[1].fire_ready=0.;g.players[1].reload=0.;g.players[1].slot=0;g.players[1].primary="a1";g.players[1].mag.a1=10;g.players[1].spray_phase=0.
	actor.input_state.crouch=false;actor.last_sprint=false;actor.sprint_release=0.;actor.spread_angle=0.;actor.reset_view(0)
	actor.position=prop.global_position+Vector3(.1,.15,2.)-Vector3.UP*actor.eye_height(false)
	g.fire(1);await create_timer(.7).timeout
	expect(g.players[1].mag.a1==9 and prop.global_position.distance_to(shot_start)>.08,"real fire path consumes ammo and pushes the hit prop")
	expect(g.arena.prop_states().size()==g.arena.props.size(),"snapshot includes complete prop set")
	var nav=g.bot_navigation;nav.refresh({},10.,g.arena.props)
	expect(nav.dynamic_solid.has(nav.cell(prop.global_position)),"bots avoid current movable prop positions")
	g.server=false;actor.local=false;actor.target_pos=Vector3(2,.12,2);actor.input_state.crouch=true;actor.headless_pose(g.players[1])
	expect(actor.global_position==actor.target_pos,"headless remote actors still follow server positions")
	expect(is_equal_approx(actor.shape.shape.height,actor.body_height*1.45/1.8),"headless optimization preserves crouch collision")
	expect(actor.camera.global_position.distance_to(actor.eye())<.001,"headless optimization preserves camera eye height")
	g.server=true;actor.local=true
	g.render_actors=false;g.add_player(2,"Headless","headless_stature_identity");g.players[2].role=1;g.actors[2].set_team(1)
	expect(not is_instance_valid(g.actors[2].character),"headless actors do not instantiate render rigs or animation players")
	expect(is_equal_approx(g.actors[2].shape.shape.height,1.72),"headless actors retain class dimensions without a render rig")
	g.server=false;g.actors[2].target_pos=Vector3(4,.2,6);g.actors[2].headless_pose(g.players[2])
	expect(not is_instance_valid(g.actors[2].character),"receiving headless clients do not animate authoritative rigs")
	expect(g.actors[2].global_position==g.actors[2].target_pos,"lightweight receiving peers still update transforms")
	replica.free();g.leave_game();g.free();await process_frame;await process_frame
	print("V1_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
