extends SceneTree
# 1.4.5: PIPER / MENDER on an ally - a green "+" where each pellet lands (random
# size and opacity, rising and fading). Real shots through game.fire; frames
# taken just after the shot, mid fade and late, from the shooter's side.
var g:Node
var out="res://../validation/v145-heal/"
func _initialize():call_deferred("run")
func shot(label:String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"MEDIC","heal_local");g.add_player(-1,"ALLY","heal_ally")
	g.phase="combat";g.clock=100.
	var base=Vector3(0,.1,g.arena.bounds.y-8.)
	for wid in ["m3","m2"]:
		var p=g.players[1];p.protect=0.;p.alive=true;p.role=int(Catalog.get_weapon(wid).get("role",4));p.primary=wid;p.slot=0;p.team=0;p.mag[wid]=int(Catalog.get_weapon(wid).mag)
		var q=g.players[-1];q.team=0;q.alive=true;q.protect=0.;q.hp=20.
		var a=g.actors[1];a.set_team(0);a.position=base;a.aim_yaw=0.;a.aim_pitch=-.05;a.rotation.y=0.;a.shown_weapon=""
		var b=g.actors[-1];b.set_team(0);b.position=base+Vector3(0,0,-6.);b.aim_yaw=PI;b.rotation.y=PI
		var camera=Camera3D.new();root.add_child(camera);camera.fov=50;camera.current=true
		camera.position=base+Vector3(1.3,1.5,-3.2);camera.look_at(base+Vector3(0,1.15,-6.))
		for i in range(20):
			a.visual(1./30.,p,g.clock);b.visual(1./30.,q,g.clock);await process_frame
		await physics_frame;await physics_frame
		var before=g.combat_fx.get_child_count()
		for volley in range(3):
			g.clock+=1.;p.mag[wid]=int(Catalog.get_weapon(wid).mag);q.hp=20.;g.fire(1)
			for i in range(7):await process_frame
		print("HEALDBG ",wid," fx children ",before," -> ",g.combat_fx.get_child_count()," ally hp ",q.hp," ally at ",b.global_position)
		var label=Catalog.get_weapon(wid).name.to_lower()
		for k in [[0,"a"],[5,"b"],[5,"c"],[5,"d"]]:
			for i in range(k[0]):await process_frame
			await shot("%s-%s"%[label,k[1]])
		camera.queue_free()
		for i in range(60):await process_frame
	print("HEAL_PLUS_OK");quit()
