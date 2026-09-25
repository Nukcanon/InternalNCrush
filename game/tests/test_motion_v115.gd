extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(30,1,30),Color.GRAY)
	g.add_player(-1,"Walker","walker");g.phase="combat";var a=g.actors[-1]
	for height in [.08,.22,.45]:
		var obstacle=StaticBody3D.new();obstacle.collision_layer=1;g.arena.add_child(obstacle)
		var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(4,height,2);shape.shape=box;obstacle.add_child(shape);obstacle.position=Vector3(0,height*.5,-1.5)
		a.position=Vector3(0,.02,1);a.velocity=Vector3.ZERO;a.reset_view(0.);a.input_state.z=-1.;a.input_state.jump=false
		await physics_frame;await physics_frame
		for i in range(150):
			g.clock+=1./60.;a.simulate(1./60.,g.clock,true);await physics_frame
		expect(a.position.z< -2.8 if height<=.28 else a.position.z>-.6,"automatic step respects height limit: "+str(height)+" actual="+str(a.position))
		obstacle.free();await physics_frame
	a.input_state.z=0.;a.position=Vector3(10,0,10)
	for direction in [Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT]:
		var corpse=AnimatedDeath.new();g.add_child(corpse);corpse.build(null,Vector3(0,.01,0),direction,0,0,0.,false,Vector3.ZERO)
		for i in range(90):await physics_frame
		var chest_direction=(corpse.model.chest.global_position-corpse.model.hips.global_position).normalized()
		expect(corpse.position.dot(direction)>.1,"lightweight corpse preserves the existing launch away from the shooter")
		expect(chest_direction.dot(direction)>.8,"falling pose follows the existing away-from-shooter launch")
		expect(corpse.position.y>-.03 and corpse.position.y<.08,"corpse rests on floor")
		expect(corpse.find_children("*","RigidBody3D",true,false).is_empty(),"Web death uses no jointed rigid bodies")
		corpse.free();await physics_frame
	g.free();await process_frame
	print("MOTION_V115_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
