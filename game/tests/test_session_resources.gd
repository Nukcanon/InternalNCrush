extends SceneTree
var failures=0
func _initialize():call_deferred("run")
func snapshot() -> Dictionary:
	return {"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))}
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	g.profile.menu_animation=false;g.profile.gunfire_reduction=true
	for i in range(8):await process_frame
	var samples=[]
	for cycle in range(9):
		g.options.map_random=false;g.options.map=[17,20,29][cycle%3];g.options.bots=2
		g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.ui.clear_panel()
		for frame in range(45):
			if frame%3==0:g.audio_bank.play("gun_a1",Vector3.ZERO,false)
			await process_frame
		g.leave_game()
		for frame in range(12):await process_frame
		var sample=snapshot();sample.cycle=cycle;samples.append(sample)
		print("SESSION_RESOURCES ",JSON.stringify(sample))
		if cycle>=6:
			var baseline=samples[cycle-3]
			for key in ["nodes","resources","objects"]:
				if sample[key]>baseline[key]+8:failures+=1;printerr("FAIL session growth ",key," ",baseline[key]," -> ",sample[key])
			if sample.texture_bytes>baseline.texture_bytes+1048576:failures+=1;printerr("FAIL texture growth")
	g.free();await process_frame;await process_frame
	HeroCharacter.scenes.clear();HeroCharacter.libraries.clear();GunModel.bases.clear();SurfaceFinish.clear_cache();ToonMaterials.clear_cache()
	for i in range(6):await process_frame
	print("SESSION_RESOURCES_RESULT failures=",failures);quit(1 if failures else 0)
