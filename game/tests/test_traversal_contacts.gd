extends SceneTree
# Exercise real character contacts, not just a direct call to the prop impulse.
var failures=0
var checks=0
var g
var a
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	print("PASS " if ok else "FAIL ",message)
	if not ok:failures+=1
func advance(count:int):
	for i in range(count):
		g.clock+=1./60.;a.simulate(1./60.,g.clock,true);await physics_frame
func reset_actor():
	a.position=Vector3(0,.02,1.);a.velocity=Vector3.ZERO;a.reset_view(0.)
	a.input_state.z=0.;a.input_state.x=0.;a.input_state.jump=false;a.input_state.crouch=false;a.input_state.sprint=false
	await advance(10)
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(30,1,30),Color.GRAY)
	g.add_player(-1,"Walker","contact_walker");g.phase="combat";a=g.actors[-1]
	for height in [.08,.22,.28,.45]:
		var ledge=g.arena.box(Vector3(0,height*.5,-1.5),Vector3(4,height,2),Color.GRAY)
		await reset_actor();a.input_state.z=-1.;await advance(150)
		expect(a.position.z< -2.8 if height<=.28 else a.position.z>-.6,"walk curb "+str(height)+"m: "+str(a.position))
		ledge.free();await physics_frame
	for kind in ["cone","canister","crate","tire","barrel","table"]:
		await reset_actor()
		var prop=InteractiveProp.new();prop.position=Vector3(0,1.,-1.);prop.configure(1,kind,true);g.arena.add_child(prop)
		for i in range(60):await physics_frame
		var before=prop.position;a.input_state.z=-1.;await advance(150)
		expect(prop.position.distance_to(before)>.25 and a.position.z<-.5,"walking pushes "+kind+" and advances: actor="+str(a.position)+" prop travel="+str(prop.position.distance_to(before)))
		prop.free();await physics_frame
	for ceiling in [false,true]:
		await reset_actor();a.position=Vector3.ZERO;await advance(10)
		var ledge=g.arena.box(Vector3(0,.6,-.8),Vector3(3,1.2,.65),Color.GRAY)
		var roof=null
		if ceiling:roof=g.arena.box(Vector3(0,2.2,-.5),Vector3(4,.2,4),Color.GRAY)
		await physics_frame;await physics_frame
		a.input_state.jump=true;a.input_state.z=-1.
		var climbed=a.try_mantle()
		expect(not climbed if ceiling else climbed and a.position.y>1.15,"mantle rejects low ceiling" if ceiling else "forward jump climbs 1.2m ledge")
		ledge.free()
		if roof:roof.free()
		await physics_frame
	await reset_actor();a.position=Vector3.ZERO;await advance(10)
	var high=g.arena.box(Vector3(0,1.5,-.8),Vector3(3,3.,.65),Color.GRAY);await physics_frame;await physics_frame
	a.input_state.jump=true;a.input_state.z=-1.
	expect(not a.try_mantle(),"mantle cannot bypass a 3m wall")
	high.free();g.free();await process_frame
	print("TRAVERSAL_CONTACTS_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
