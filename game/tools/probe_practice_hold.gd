extends SceneTree
# 1.5.1 (the user: holding a grenade the hand sat far to the left): the practice range
# run by the game's own loop - switch to the throwable, hold, throw, hold the next -
# screenshots and the held item's camera-space place over time. Args: role=N gadget=N
var g:Node
func _initialize():call_deferred("run")
func shot(name:String):
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://../validation/practice-hold/")
	root.get_texture().get_image().save_jpg("res://../validation/practice-hold/%s.jpg"%name,.8)
	var a=g.actors[1];var p=g.players[1]
	var it=a.camera.global_transform.affine_inverse()*a.view_item.global_position if is_instance_valid(a.view_item) and a.view_item.is_inside_tree() else Vector3.ZERO
	print("HOLD %s slot %d item %s gun %s cooking %s throw %.2f count %d"%[name,int(p.slot),str(it.snapped(Vector3.ONE*.001)),str(a.gun.position.snapped(Vector3.ONE*.001)),str(p.get("cooking",0)),float(p.get("throw_until",-1.))-g.clock,int(p.get("gadget_count",0))])
func wait(seconds:float):
	var until=Time.get_ticks_msec()+int(seconds*1000.)
	while Time.get_ticks_msec()<until:await process_frame
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.ui.clear_panel();PracticeSession.start(g)
	await wait(1.)
	var role=1;var gadget=8
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("role="):role=int(str(arg).substr(5))
		if str(arg).begins_with("gadget="):gadget=int(str(arg).substr(7))
	var p=g.players[1];var a=g.actors[1]
	p.role=role;p.primary=Catalog.first(role);p.gadget=gadget;GadgetLoadout.reset(p);a.shown_role=-1
	await wait(.5)
	g.command("slot",{"slot":2});await wait(.6);await shot("a_held")
	for n in range(2):
		g.trigger_seq+=1;a.input_state.trigger_seq=g.trigger_seq;a.input_state.fire=true
		g.command("trigger_press",{"seq":g.trigger_seq})
		await wait(.25);await shot("b%d_cook"%n)
		await wait(.4)
		a.input_state.fire=false;g.command("trigger_release",{"seq":g.trigger_seq})
		var released=g.clock
		for k in range(14):
			var target=released+.05*(k+1)
			while g.clock<target:await process_frame
			await shot("c%d_%03d"%[n,int(round((g.clock-released)*100))])
		await wait(2.)
	print("HOLD_DONE");quit()
