extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	var world=Node3D.new();root.add_child(world)
	var floor_body=StaticBody3D.new();world.add_child(floor_body)
	var collision=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(30,.2,30);collision.shape=box;collision.position.y=-.1;floor_body.add_child(collision)
	await physics_frame;await physics_frame
	for hit in [Vector3(0,1.63,0),Vector3(0,1.24,0),Vector3(.1,.5,0)]:
		var rag=PhysicsRagdoll.new();world.add_child(rag);rag.build(null,Vector3.ZERO,Vector3(1,.08,0),0,0,0.,false,Vector3.ZERO,hit)
		var start=rag.bodies[0].global_position;var distance=0.
		for frame in range(150):
			await physics_frame
			var delta=rag.bodies[0].global_position-start;distance=maxf(distance,Vector2(delta.x,delta.z).length())
		expect(distance>=1. and distance<=3.1,"native exaggerated launch stays within 1–3m: "+str(distance))
		expect(rag.bodies.all(func(b):return b.global_position.is_finite() and b.global_position.y>-.3),"native corpse stays finite and contacts the floor")
		var torso=(rag.model.chest.global_position-rag.model.hips.global_position).normalized()
		expect(absf(torso.y)<.4,"native corpse finishes lying flat: torso="+str(torso))
		expect(rag.bodies.filter(func(b):return b.has_meta("fatal_impact")).size()==1,"one struck limb receives the impact")
		if hit.y>1.5:expect(rag.bodies.any(func(b):return str(b.get_meta("fatal_impact_part","")).ends_with("Head")),"headshot remains a head impact after the pose changes")
		rag.free();await physics_frame
	var airborne=PhysicsRagdoll.new();world.add_child(airborne);airborne.build(null,Vector3(0,4,0),Vector3.FORWARD,0,0,0.,false,Vector3.ZERO)
	for frame in range(210):await physics_frame
	expect(airborne.bodies[0].global_position.y<.6 and airborne.bodies[0].global_position.y>-.2,"airborne corpse falls onto the floor before settling")
	airborne.free();world.free();await process_frame
	print("RAGDOLL_V115_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
