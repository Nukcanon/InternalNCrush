extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720)
	var background=ColorRect.new();background.color=Color("243541");background.size=Vector2(1280,720);root.add_child(background)
	var symbols=HudSymbols.new();root.add_child(symbols)
	symbols.draw.connect(func():
		for role in range(6):
			for row in range(3):symbols.badge(role,Vector2(180+role*180,160+row*190),12. if row==2 else 0.,35.,row!=1,.75))
	for n in range(5):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://validation")
	if root.get_texture().get_image().save_png("res://validation/skill-badges-ready-disabled-cooldown.png")!=OK:quit(1);return
	print("SKILL_BADGE_RENDER_OK roles=6 states=3");quit()
