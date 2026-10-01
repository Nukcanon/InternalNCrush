extends SceneTree
# 1.4.5: can a turret of each level see (and so shoot) an enemy standing or
# crouching right behind a deployed cover? Prints the visible body point.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.options.map_random=false;g.options.map=13;g.build_world();g.phase="lobby"
	g.add_player(1,"OWNER","probe_tc_1");g.add_player(2,"ENEMY","probe_tc_2");g.phase="combat";g.clock=100.
	var p=g.players[1];var q=g.players[2];p.team=0;q.team=1;q.alive=true;q.protect=0.
	var base=Vector3(0,.1,g.arena.bounds.y-8)
	# cover 9 m ahead, enemy 1 m behind it
	var cover_at=base+Vector3(0,0,-9.);var enemy_at=base+Vector3(0,0,-10.)
	g.devices[900]={"kind":"cover","pos":Vector3(cover_at.x,0.,cover_at.z),"yaw":0.,"team":0,"owner":1,"hp":300.,"max_hp":300.,"level":1,"expires":1e9}
	g.update_world_visuals(.016)
	print("COVER node at ",g.device_nodes[900].global_position," want ",g.devices[900].pos)
	g.device_nodes[900].global_position=g.devices[900].pos
	await physics_frame;await physics_frame
	var ea=g.actors[2];ea.position=enemy_at;ea.velocity=Vector3.ZERO
	for crouch in [false,true]:
		ea.input_state.crouch=crouch
		await physics_frame;await physics_frame
		var line="TURRETCOVER enemy %s:"%("crouching" if crouch else "standing")
		for level in range(1,5):
			var d={"kind":"turret","pos":Vector3(base.x,0.,base.z),"yaw":0.,"level":level,"team":0,"owner":1}
			var v=TurretLogic.visible_point(g,d,2,[])
			line+=" L%d(origin %.2f)=%s"%[level,TurretLogic.origin(d).y-base.y,"SEES %.2f"%(v.y-enemy_at.y) if v!=Vector3.INF else "blocked"]
		print(line)
	g.device_nodes[900].global_position=Vector3(0,-50,0);ea.input_state.crouch=false;await physics_frame;await physics_frame
	var open="TURRETCOVER no cover:"
	for level in range(1,5):
		var d2={"kind":"turret","pos":Vector3(base.x,0.,base.z),"yaw":0.,"level":level,"team":0,"owner":1}
		open+=" L%d=%s"%[level,"SEES" if TurretLogic.visible_point(g,d2,2,[])!=Vector3.INF else "blocked"]
	print(open)
	quit()
