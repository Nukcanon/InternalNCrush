extends SceneTree
# 1.4.5: runs the menu background demo and counts frames in which its chase
# camera sits inside a wall or prop (a sphere around the lens intersects
# layer 1|8) or has no clear line to the bot it follows. Arg: seconds.
func _initialize():call_deferred("run")
func run():
	var seconds=float(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 40.
	var demo=load("res://scripts/menu_demo.gd").new();root.add_child(demo)
	for i in range(10):await process_frame
	var shape=SphereShape3D.new();shape.radius=.12
	var frames=0;var inside=0;var blocked=0;var started=Time.get_ticks_msec();var worst_inside=[]
	while Time.get_ticks_msec()-started<seconds*1000.:
		await physics_frame
		var world:World3D=demo.viewport.find_world_3d()
		if world==null:
			if frames==0:print("DEMO_CAMERA no world yet")
			continue
		var space=world.direct_space_state;frames+=1
		var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform=Transform3D(Basis.IDENTITY,demo.camera.global_position);q.collision_mask=1|8
		if not space.intersect_shape(q,1).is_empty():
			inside+=1
			if worst_inside.size()<5:worst_inside.append(demo.camera.global_position)
		if is_instance_valid(demo.followed):
			var focus=demo.followed.global_position+Vector3.UP*1.5
			if not space.intersect_ray(PhysicsRayQueryParameters3D.create(focus,demo.camera.global_position,1|8)).is_empty():blocked+=1
	print("DEMO_CAMERA map=%s frames=%d inside_wall=%d blocked_line=%d bots=%d samples=%s"%[str(demo.match_game.options.map),frames,inside,blocked,demo.match_game.actors.size(),str(worst_inside)])
	quit()
