extends SceneTree
# 1.4.5: the first-person throw after the user's reference video - at rest
# (free hand open in front), pin pull (hands meet, ring pulled), aim (free arm
# out ahead, throwing hand back), overhand release and follow-through.
# Args: "left" for a left-handed player.
var g:Node
var out="res://../validation/v145-throw/"
func _initialize():call_deferred("run")
func shot(label:String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
func settle(a,p,frames:int=10,step:float=0.):
	for i in range(frames):
		g.clock+=step;a.visual(1./30.,p,g.clock);await process_frame
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","throw_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=2;p.gadget=1;p.team=0;p.gadget_count=3
	if "left" in OS.get_cmdline_user_args():p.hand=-1
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	await settle(a,p,30);await shot("00-idle")
	var tag=0
	p.cooking=1;p.grenade_started=g.clock
	for age in [.06,.12,.18,.26,.34,.42,.50,.62,1.2]:
		while g.clock<p.grenade_started+age-.0001:
			g.clock=minf(p.grenade_started+age,g.clock+1./60.);a.visual(1./60.,p,g.clock);await process_frame
		tag+=1;await shot("%02d-cook-%03d"%[tag,int(age*100)])
	# release: step the clock through the throw
	p.cooking=0;p.throw_until=g.clock+Actor.THROW_TIME
	var phase_shots=[.12,.26,.40,.55,.70,.85,.97];var t0=g.clock
	for ph in phase_shots:
		var target=t0+Actor.THROW_TIME*ph
		while g.clock<target-.0001:
			g.clock=minf(target,g.clock+1./60.);a.visual(1./60.,p,g.clock);await process_frame
		tag+=1;await shot("%02d-throw-%02d"%[tag,int(ph*100)])
	print("THROW_REVIEW_OK");quit()
