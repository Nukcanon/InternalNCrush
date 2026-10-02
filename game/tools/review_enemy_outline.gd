extends SceneTree
# 1.4.6: enemies as the player sees them in a match (ink outline width at the
# real 1920x1080 view), at 4, 10 and 22 m. Writes validation/v146-outline/.
var out="res://../validation/v146-outline/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1920,1080);DisplayServer.window_set_size(Vector2i(1920,1080))
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=31
	g.build_world();g.add_player(1,"PLAYER","outline_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.slot=0;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	var start=Vector3(0,.1,g.arena.bounds.y-8.)
	for s in g.arena.spawn_points[0]:
		start=s;break
	a.position=start;a.reset_view(0);await physics_frame
	var ahead=-a.global_basis.z;ahead.y=0;ahead=ahead.normalized();var right=ahead.cross(Vector3.UP)
	var spots=[[4.,-.8,0],[10.,1.5,2],[22.,-1.,5]]
	for i in range(spots.size()):
		var id=-(i+1);g.add_player(id,"적 %d"%(i+1),"enemy%d"%i);var q=g.players[id];q.team=1;q.role=spots[i][2];q.primary=Catalog.first(q.role);q.alive=true
		var e=g.actors[id];e.set_team(1);g.spawn(id);e.position=start+ahead*spots[i][0]+right*spots[i][1];e.reset_view(atan2(ahead.x,ahead.z));q.protect=0.
	for i in range(40):
		g.clock+=1./30.
		for id in g.actors:g.actors[id].visual(1./30.,g.players[id],g.clock)
		await process_frame
	for id in g.players:if id<0:g.players[id].protect=0.
	for i in range(6):
		g.clock+=1./30.
		for id in g.actors:g.actors[id].visual(1./30.,g.players[id],g.clock)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"enemies_1080p.png")
	print("ENEMY_OUTLINE_OK");quit()
