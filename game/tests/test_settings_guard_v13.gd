extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.profile.menu_animation=false
	g.ui.settings();var baseline=g.ui.settings_baseline.duplicate(true)
	g.profile.decor_quality=(int(g.profile.decor_quality)+1)%3
	g.ui.settings_exit.call();assert(is_instance_valid(g.ui.settings_dialog))
	g.ui.settings_dialog.custom_action.emit("discard");await process_frame
	assert(g.profile.decor_quality==baseline.decor_quality)
	g.ui.settings();g.profile.shadow_quality=(int(g.profile.shadow_quality)+1)%3
	var chosen=g.profile.shadow_quality;g.ui.toggle_pause();assert(is_instance_valid(g.ui.settings_dialog))
	g.ui.settings_dialog.confirmed.emit();await process_frame
	assert(g.profile.shadow_quality==chosen)
	g.free();await process_frame;print("SETTINGS_GUARD_V13_PASS");quit()
