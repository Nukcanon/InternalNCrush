extends SceneTree
func _initialize():call_deferred("run")
func run():
	var mode="empty"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--case="):mode=arg.trim_prefix("--case=")
	var holder=Node3D.new();root.add_child(holder)
	var camera=Camera3D.new();holder.add_child(camera);camera.current=true;camera.position.z=4
	if mode=="shader":
		var node=MeshInstance3D.new();holder.add_child(node);node.mesh=BoxMesh.new();node.material_override=ToonMaterials.make()
	elif mode=="menu":
		var game=load("res://scripts/game.gd").new();holder.add_child(game)
	elif mode=="arena":
		var arena=Arena.new();holder.add_child(arena);arena.build(17)
	elif mode in ["game_no_actors","game_actors"]:
		var game=load("res://scripts/game.gd").new();holder.add_child(game)
		game.render_actors=mode=="game_actors";game.options.map_random=false;game.options.map=17;game.options.bots=1
		game.host_game(OfflineMultiplayerPeer.new());game.start_match();game.ui.clear_panel()
	for i in range(60):await process_frame
	holder.free();ToonMaterials.clear_cache();SurfaceFinish.clear_cache()
	CharacterVisual.templates.clear();OperatorSkin.templates.clear();WeaponVisual.web_templates.clear()
	for i in range(12):await process_frame
	print("TEXTURE_LIFETIME ",mode);quit()
