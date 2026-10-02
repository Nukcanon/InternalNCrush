extends SceneTree
# 1.4.6: the pin pull and throw as a continuous sequence (every 1/30 s) for a
# video - frames in validation/v146-throw/seq/.
var g:Node
var out="res://../validation/v146-throw/seq/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","throw_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=2;p.gadget=1;p.team=0;p.gadget_count=3
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	for i in range(30):g.clock+=1./30.;a.visual(1./30.,p,g.clock);await process_frame
	var n=0
	var step=1./30.
	for i in range(10):
		g.clock+=step;a.visual(step,p,g.clock);await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+"f%03d.png"%n);n+=1
	p.cooking=1;p.grenade_started=g.clock
	for i in range(30):
		g.clock+=step;a.visual(step,p,g.clock);await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+"f%03d.png"%n);n+=1
	p.cooking=0;p.throw_until=g.clock+Actor.THROW_TIME
	for i in range(24):
		g.clock+=step*.5;a.visual(step*.5,p,g.clock);await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+"f%03d.png"%n);n+=1
	print("THROW_SEQ_OK ",n);quit()
