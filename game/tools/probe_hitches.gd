extends SceneTree
# 1.4.5: frame-time hitches through the first seconds of a bot match (the
# user sees a 1-2 s freeze shortly after the start). Starts a real bot match
# through Game.start_bot_match, then logs every frame over 40 ms with the
# Prof sections that grew most during it (run with INC_PROFILE=1).
# Args: [map] [bots] [seconds]
var g:Node
func _initialize():call_deferred("run")
func run():
	var args=OS.get_cmdline_user_args()
	var map=int(args[0]) if args.size()>0 else 7;var bots=int(args[1]) if args.size()>1 else 9;var seconds=float(args[2]) if args.size()>2 else 20.
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(30):await process_frame
	g.options.map_random=false;g.options.map=map;g.options.bots=bots;g.options.mode=0;g.options.minutes=10;g.options.classes=true
	if "warm" in args:
		var tw=Time.get_ticks_msec();var warm=Node3D.new();root.add_child(warm);warm.position=Vector3(0,-50,0)
		for role in range(6):
			var h=HeroCharacter.new();warm.add_child(h);h.build(role,role%2,false);h.position.x=role*2;h.set_armor(role%3)
		for wid in Catalog.weapons:
			var gm=GunModel.new();warm.add_child(gm);gm.build(Catalog.get_weapon(wid),true)
		var cam=Camera3D.new();warm.add_child(cam);cam.position=Vector3(5,2,12);cam.current=true
		for i in range(3):await process_frame
		warm.queue_free();await process_frame
		print("HITCH warm-up took %d ms"%(Time.get_ticks_msec()-tw))
	Prof.data.clear();var t0=Time.get_ticks_msec()
	g.start_bot_match({"role":0,"primary":"a1","secondary":"pistol","armor":0,"gadget":1,"team":-1})
	print("HITCH start_bot_match took %d ms map=%s cached_nav=%s building=%s"%[Time.get_ticks_msec()-t0,str(g.options.map),str(g.arena.has_meta("navigation_cache")),str(g.arena.building)])
	var parts=[]
	for key in Prof.data:parts.append("%s=%dms"%[key,int(Prof.data[key])/1000])
	parts.sort();print("HITCH start sections: ",", ".join(parts))
	var last=Time.get_ticks_usec();var started=Time.get_ticks_msec();var frames=0;var worst=0.;var over=0
	var all=func() -> Dictionary:
		var d=Prof.data.duplicate()
		for k in g.prof:d["game."+k]=g.prof[k]
		return d
	var prof_before=all.call()
	while Time.get_ticks_msec()-started<seconds*1000.:
		await process_frame
		var now=Time.get_ticks_usec();var dt=(now-last)/1000.;last=now;frames+=1
		if dt>40.:
			over+=1;worst=maxf(worst,dt)
			var grown=[]
			var now_all=all.call()
			for key in now_all:
				var delta=int(now_all[key])-int(prof_before.get(key,0))
				if delta>2000:grown.append("%s=%dms"%[key,delta/1000])
			print("HITCH t=%.2fs frame %.0f ms objects=%d nodes=%d %s"%[(Time.get_ticks_msec()-started)/1000.,dt,Performance.get_monitor(Performance.OBJECT_COUNT),Performance.get_monitor(Performance.OBJECT_NODE_COUNT),", ".join(grown)])
		prof_before=all.call()
		# Keep the local player moving and shooting so the first-use costs show.
		if g.actors.has(g.local_id):
			var a=g.actors[g.local_id];a.input_state.z=-1.;a.input_state.fire=int(frames/30)%3==0
	print("HITCH_SUMMARY frames=%d over40ms=%d worst=%.0f ms vram=%.1f MB"%[frames,over,worst,Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.])
	quit()
