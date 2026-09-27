extends SceneTree
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	var game=load("res://scripts/game.gd").new();game.demo_mode=true;game.demo_map=13;game.render_actors=true;root.add_child(game)
	await process_frame
	if game.players.size()!=6 or game.actors.size()!=6:
		printerr("FAIL: game initialization did not create six combatants");game.free();quit(1);return
	var camera=Camera3D.new();game.add_child(camera);camera.position=Vector3(0,8,12);camera.look_at(Vector3(0,1,0));camera.current=true
	var maxima=[];var samples=[]
	for cycle in range(12):
		var peak=0
		for frame in range(180):
			var start=Time.get_ticks_usec()
			if frame%30==0:
				for id in game.players:
					var p=game.players[id];p.slot=(frame/30)%2
					p.armor_max=((frame/30)%3)*25
			if frame%60==0:
				var pos=Vector3(cycle%3,0,-2)
				game.combat_fx.explosion(pos)
				game.combat_fx.ragdoll(null,pos,Vector3.FORWARD,cycle%6,cycle%2,0.,false,Vector3.ZERO)
			for shot in range(8):game.combat_fx.beam(Vector3(shot,1,2),Vector3(shot+1,1,-15))
			if frame%10==0:game.combat_fx.eject_case(Vector3(0,1,0),Vector3.RIGHT,Vector3.UP,0.,frame)
			await physics_frame;await process_frame
			peak=maxi(peak,Time.get_ticks_usec()-start)
		game.combat_fx.clear()
		for i in range(4):await process_frame
		var s={"cycle":cycle,"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"mesh_cache":MeshFactory.meshes.size(),"armor_templates":ArmorVisual.templates.size(),"max_frame_ms":peak/1000.}
		samples.append(s);print("COMBAT_SAMPLE ",JSON.stringify(s))
		expect(ArmorVisual.templates.size()<=6,"armor cache limited by quality and level")
		expect(MeshFactory.meshes.size()<=MeshFactory.MESH_CACHE_LIMIT,"mesh cache bounded")
	# Later cycles may load a new operator; compare identical warmed final cycles.
	expect(samples[-1].nodes<samples[2].nodes+400,"no retained per-cycle effects")
	expect(samples[-1].static_bytes<samples[2].static_bytes+32*1024*1024,"bounded post-warmup memory growth")
	game.free();await process_frame;await process_frame
	print("STABILITY_RESULT failures=",failures);quit(1 if failures else 0)
