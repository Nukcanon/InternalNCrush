extends SceneTree
# 1.5.0 (the user): a pump shotgun loading shells back to back - the hand stays
# down at the shells between them and works the pump once after the last; a shot
# cutting the loading works the pump in its short delay; the pump itself slides.
# Frames every 0.1 s through the real server reload (validation/shell-chain/).
var g:Node
var out="res://../validation/shell-chain/"
func _initialize():call_deferred("run")
func grab() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var full=root.get_texture().get_image();full.convert(Image.FORMAT_RGB8);var s=full.get_size()
	var img=full.get_region(Rect2i(int(s.x*.3),int(s.y*.3),int(s.x*.7),int(s.y*.7)));img.resize(480,270,Image.INTERPOLATE_BILINEAR);return img
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","v14_local");g.local_id=1
	g.ui.show_hud();g.phase="combat";g.clock=100.;g.options.infinite=true;g.remaining=999999.
	for i in range(30):await process_frame
	var wid="e1";var w=Catalog.get_weapon(wid)
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=int(w.role);p.primary=wid;p.slot=0;p.team=0;p.hand=1
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	for scene in ["chain","cut"]:
		p.mag[wid]=1 if scene=="chain" else 0;p.reload=0.;a.input_state.fire=false;p.input_time=g.clock
		for i in range(20):g.clock+=1./60.;p.input_time=g.clock;g.server_tick(1./60.);a.visual(1./60.,p,g.clock)
		g.begin_reload(1)
		var sheet=Image.create(480*6,270*4,false,Image.FORMAT_RGB8);var k=0;var fired=false
		var frames=24
		for f in range(frames):
			for i in range(6):
				g.clock+=1./60.;p.input_time=g.clock
				if scene=="cut" and not fired and int(p.mag.get(wid,0))>=2:a.input_state.fire=true;fired=true
				elif fired:a.input_state.fire=false
				g.server_tick(1./60.);a.visual(1./60.,p,g.clock)
			var img=await grab();sheet.blit_rect(img,Rect2i(0,0,480,270),Vector2i(480*(k%6),270*(k/6)));k+=1
			print("SHELL ",scene," f",f," R ",snappedf(float(p.reload),.01)," C ",snappedf(g.clock,.01)," alive ",p.alive," phase ",g.phase," mag ",p.mag.get(wid,0)," reload ",snappedf(MagazineReload.progress(g,p,w),.01)," chain ",a.shell_chain," pump ",snappedf(g.clock-a.shell_pump_at,.01))
		sheet.save_jpg(out+scene+".jpg",.85)
	print("SHELL_OK");quit()
