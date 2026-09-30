extends SceneTree
# Frame time of the first and a later occurrence of each visual effect in a
# rendered match: a first-use spike means a shader/material compiles mid-fight.
var g:Node
func _initialize():call_deferred("run")
func frame_ms(action:Callable) -> float:
	await process_frame
	Prof.data.clear();g.prof.clear()
	var start=Time.get_ticks_usec();action.call();var call_ms=(Time.get_ticks_usec()-start)/1000.
	var worst=0.
	for i in range(6):
		var t=Time.get_ticks_usec();await process_frame;worst=maxf(worst,(Time.get_ticks_usec()-t)/1000.)
	print("   call=%.1f ms sections=%s game=%s"%[call_ms,str(Prof.data),str(g.prof)])
	return maxf(worst,(Time.get_ticks_usec()-start)/1000./6.)
func run():
	g=load("res://scripts/game.gd").new();g.render_actors=true;root.add_child(g)
	for i in range(10):await process_frame
	var preset=int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 1
	g.profile.merge(GraphicsOptions.PRESETS[preset],true);g.profile.graphics_auto=false;g.profile.menu_animation=false;GraphicsOptions.apply(g)
	g.options.map_random=false;g.options.map=17;g.options.max_players=4;g.options.bots=3;g.options.mode=0
	g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.ui.clear_panel()
	await create_timer(3.).timeout
	var a=g.actors[1];var ahead=a.eye()+a.camera.global_basis*Vector3(0,-.5,-6.)
	var effects={
		"explosion":func():g.combat_fx.explosion(ahead),
		"burst_smoke":func():g.combat_fx.burst("smoke",ahead,Color.GRAY),
		"skill_burst":func():g.combat_fx.skill_burst(3,ahead,Color.ORANGE),
		"armor_impact":func():g.combat_fx.armor_impact(ahead,Vector3.UP,Color.CYAN),
		"beam":func():g.combat_fx.beam(a.eye()+Vector3.DOWN*.3,ahead,false,true),
		"heal_area":func():g.combat_fx.heal_area(ahead),
		"death":func():
			for id in g.players:
				if id!=1 and g.players[id].alive:
					g.actors[id].position=ahead;g.players[id].protect=0.;g.players[id].invulnerable=0.
					g.damage(id,1000.,1,false,"a1",a.eye(),ahead+Vector3.UP);break}
	for name in effects:
		var first=await frame_ms(effects[name])
		await create_timer(1.).timeout
		var second=await frame_ms(effects[name])
		print("HITCH %s first=%.1f ms later=%.1f ms"%[name,first,second])
	g.free();await process_frame;quit()
