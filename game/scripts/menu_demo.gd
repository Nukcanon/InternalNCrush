extends SubViewportContainer
## A real isolated offline match. It neither opens ENet ports nor saves a profile.
var viewport:SubViewport
var match_game:Node3D
var camera:Camera3D
var elapsed=0.
var multiplayer_path:NodePath
var render_accumulator=0.
func _ready():
	stretch=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
	viewport=SubViewport.new();viewport.size=Vector2i(1280,720);viewport.own_world_3d=true;viewport.handle_input_locally=false;viewport.gui_disable_input=true;viewport.audio_listener_enable_3d=false;add_child(viewport)
	GraphicsOptions.apply_viewport(viewport)
	multiplayer_path=viewport.get_path();get_tree().set_multiplayer(SceneMultiplayer.new(),multiplayer_path)
	match_game=load("res://scripts/game.gd").new();match_game.demo_mode=true;viewport.add_child(match_game)
	camera=Camera3D.new();camera.fov=65.;camera.far=160.;viewport.add_child(camera);camera.current=true
	update_camera(0.)
func _process(dt):
	elapsed+=dt;render_accumulator+=dt
	if render_accumulator>=1./[15.,24.,30.][GraphicsOptions.detail]:
		render_accumulator=0.;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	update_camera(dt)
func update_camera(dt):
	var target=Vector3(0,1.4,0)
	var angle=elapsed*.035
	var desired=target+Vector3(sin(angle)*13.,7.,cos(angle)*17.)
	camera.position=desired if dt==0 else camera.position.lerp(desired,1.-exp(-dt*2.))
	camera.look_at(target)
func _exit_tree():
	if not multiplayer_path.is_empty():get_tree().set_multiplayer(get_tree().get_multiplayer(),multiplayer_path)
