extends SceneTree
# 1.5.4 (the user): on phones the door prompt names the interact button, and that button
# blinks softly yellow while it would do something. Touch controls forced on, standing at a
# door. Output validation/touch-interact.jpg (two moments of the blink side by side).
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	TouchControls.supported_cache=1
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","touch_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	var door=g.arena.doors.values()[0]
	var front:Vector3=door.global_transform.basis.z.normalized();front.y=0.;front=front.normalized()
	a.position=door.global_position+front*2.0;a.position.y=door.global_position.y+.05
	var look=door.global_position-a.position;a.reset_view(atan2(-look.x,-look.z));await physics_frame
	var shots=[]
	for k in range(2):
		for i in range(30+k*11):g.clock+=1./60.;a.visual(1./60.,p,g.clock);await process_frame
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image();img.resize(960,540,Image.INTERPOLATE_BILINEAR);shots.append(img)
	var sheet=Image.create(1920,540,false,Image.FORMAT_RGBA8)
	for i in range(2):sheet.blit_rect(shots[i],Rect2i(0,0,960,540),Vector2i(i*960,0))
	sheet.save_jpg("res://../validation/touch-interact.jpg",.88)
	print("TOUCH_DONE door=",InteractiveDoor.target(g,1)!=null," hint=",g.ui.interaction_hint.text);quit()
