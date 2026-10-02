extends SceneTree
# 1.5.1: explosion scorch marks (floor + nearby wall) and the outline of people
# at 8 / 20 / 35 m with the distance fade on and off. Output validation/fx151/.
var g:Node
func _initialize():call_deferred("run")
func shot(name:String):
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://../validation/fx151/")
	root.get_texture().get_image().save_jpg("res://../validation/fx151/%s.jpg"%name,.88)
func outline_fade(on:bool):
	for a in g.actors.values():
		for m in a.find_children("*","MeshInstance3D",true,false):
			for mat in [m.material_override,m.get_surface_override_material(0) if m.mesh and m.mesh.get_surface_count()>0 else null]:
				var cur=mat
				while cur!=null:
					if cur is ShaderMaterial and cur.shader and cur.shader.code.contains("ink_far"):cur.set_shader_parameter("fade_near",10. if on else 1000.);cur.set_shader_parameter("fade_far",40. if on else 2000.)
					cur=cur.next_pass if cur is Material else null
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();g.render_actors=true;root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","fx_local")
	for i in range(3):g.add_player(-i-1,"BOT","fx_bot%d"%i)
	g.ui.show_hud();g.phase="combat";g.clock=100.
	for id in g.players:g.spawn(id)
	var p=g.players[1];var a=g.actors[1];a.set_local(true)
	var start=Vector3(0,.1,g.arena.bounds.y-8.)
	a.position=start;a.reset_view(0);a.aim_pitch=-.25;a.input_state.pitch=-.25
	var fwd=Vector3(0,0,-1)
	for k in range(3):
		var b=g.actors[-k-1];var q=g.players[-k-1];q.alive=true;q.protect=0.;q.invulnerable=0.;q.team=1;b.set_team(1);b.position=start+fwd*[8.,20.,35.][k]+Vector3([-1.5,1.5,0.][k],0,0);b.rotation.y=0.;b.aim_yaw=0.
	for i in range(30):g.clock+=1./60.;g.render_update(1./60.) if g.has_method("render_update") else null;await process_frame
	p.protect=0.
	for i in range(20):
		for id in g.actors:g.actors[id].visual(1./60.,g.players[id],g.clock)
		await process_frame
	outline_fade(false);await shot("outline_before")
	outline_fade(true);await shot("outline_after")
	# scorch: an explosion 4 m ahead and one beside the nearest wall
	var space=a.get_world_3d().direct_space_state
	var hit={};var wall_dir=Vector3.ZERO
	for d in [Vector3(1,0,0),Vector3(-1,0,0),Vector3(0,0,1),Vector3(0,0,-1)]:
		var h=space.intersect_ray(PhysicsRayQueryParameters3D.create(start+Vector3.UP,start+Vector3.UP+d*25.,1))
		if not h.is_empty() and (hit.is_empty() or h.position.distance_to(start)<hit.position.distance_to(start)):hit=h;wall_dir=d
	var at=start+fwd*4.
	g.effect("explosion",at+Vector3.UP*.2,Vector3(8.,0,0),1) # a grenade (8 m)
	if not hit.is_empty():g.effect("rocket_explosion",hit.position-wall_dir*1.2+Vector3.DOWN*.7,Vector3(9.,0,0),1) # a rocket (9 m)
	var until=Time.get_ticks_msec()+6000
	while Time.get_ticks_msec()<until:await process_frame
	a.camera.rotation.x=-.5
	for i in range(10):await process_frame
	await shot("scorch_floor")
	print("SCORCH marks ",g.combat_fx.scorches.size()," wall ",hit.get("position",Vector3.ZERO)," dir ",wall_dir)
	for m in g.combat_fx.scorches:print("  mark at ",m.global_position.snapped(Vector3.ONE*.01)," up ",m.global_basis.y.snapped(Vector3.ONE*.01))
	if not hit.is_empty():
		a.position=hit.position-wall_dir*5.+Vector3.DOWN*1.;a.rotation.y=atan2(-wall_dir.x,-wall_dir.z);a.camera.rotation.x=-.15
		for i in range(10):await process_frame
		await shot("scorch_wall")
	print("FX_DONE");quit()
