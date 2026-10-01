extends SceneTree
# 1.4.5: the class / equipment screen as the player sees it - the item preview
# above its description (tight framing, no empty band) for a weapon, gadgets
# and the armour (hero standing at ease).
var out="res://../validation/v145-gear/"
func _initialize():call_deferred("run")
func shot(label:String):
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1600,900);DisplayServer.window_set_size(Vector2i(1600,900))
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(15):await process_frame
	g.set_physics_process(false);g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","gear_local");g.phase="combat";g.clock=100.
	for role in [0,2,5]:
		g.players[1].role=role;g.players[1].primary=Catalog.first(role)
		g.ui.gear();await process_frame
		for cat in [0,2,3]:
			g.ui.gear_category=cat;g.ui.preview_secondary=false;g.ui.preview_kind=[1,1,2,3,4][cat]
			if cat==3:g.ui.gear_armor.select(2)
			g.ui.refresh_gear_detail();g.ui.refresh_gear_cards()
			await shot("role%d-cat%d"%[role,cat])
	print("GEAR_SCREEN_OK");quit()
