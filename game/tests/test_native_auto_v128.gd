extends SceneTree
func _initialize():call_deferred("run")
func run():
	var game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
	assert(is_instance_valid(game.native_graphics))
	game.profile.graphics_auto=true;game.profile.width=1920;game.profile.height=1080
	var before=game.profile.duplicate(true)
	game.native_graphics.level=0;GraphicsOptions.apply(game)
	assert(GraphicsOptions.detail==0 and GraphicsOptions.corpse_quality==0)
	assert(game.profile==before,"Auto must not rewrite saved display or custom settings")
	game.native_graphics.level=2;GraphicsOptions.apply(game)
	assert(GraphicsOptions.detail==2 and GraphicsOptions.physics_effects==2)
	assert(GraphicsOptions.antialias==2 and GraphicsOptions.shadows==1,"Automatic high enables full quality without altering resolution")
	game.profile.graphics_auto=false;game.profile.shadow_quality=1;game.profile.lighting_quality=2;game.profile.antialias=2
	GraphicsOptions.apply(game)
	assert(GraphicsOptions.shadows==1 and GraphicsOptions.antialias==2,"Manual settings take over")
	var world=Node3D.new();root.add_child(world)
	var sun=DirectionalLight3D.new();sun.name="Sun";sun.shadow_enabled=false;world.add_child(sun)
	GraphicsOptions.apply_world(world)
	assert(sun.shadow_enabled,"Manual shadows work in mixed indoor/outdoor maps")
	GraphicsOptions.shadows=0;GraphicsOptions.apply_world(world)
	assert(not sun.shadow_enabled,"Off reliably disables sun shadows")
	world.free()
	game.free();await process_frame;print("NATIVE_AUTO_V128_PASS");quit()
