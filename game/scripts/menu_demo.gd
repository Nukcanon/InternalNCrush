extends SubViewportContainer
## A real isolated offline match. It neither opens ENet ports nor saves a profile.
var viewport:SubViewport
var match_game:Node3D
var camera:Camera3D
var elapsed=0.
var multiplayer_path:NodePath
var render_accumulator=0.
func _ready():
	stretch=true;stretch_shrink=1;mouse_filter=Control.MOUSE_FILTER_IGNORE
	viewport=SubViewport.new();viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;viewport.size=Vector2i(1280,720);viewport.own_world_3d=true;viewport.handle_input_locally=false;viewport.gui_disable_input=true;viewport.audio_listener_enable_3d=false;add_child(viewport)
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
	# 1.4: a chase camera behind one bot at a time (streets are framed by tall
	# buildings, so an overhead orbit would sit inside them). It never clips a
	# wall: the view is pulled in front of anything between it and the bot.
	var bots=[]
	if is_instance_valid(match_game) and "actors" in match_game:
		for actor in match_game.actors.values():
			if is_instance_valid(actor) and actor.is_inside_tree() and actor.visible:bots.append(actor)
	if bots.is_empty():
		var target=Vector3(0,1.4,0);var angle=elapsed*.035
		camera.position=target+Vector3(sin(angle)*6.,2.5,cos(angle)*6.);camera.look_at(target);return
	var actor:Node3D=bots[int(elapsed/11.)%bots.size()]
	var forward=-actor.global_basis.z;forward.y=0.;forward=forward.normalized() if forward.length()>.01 else Vector3.FORWARD
	var focus=actor.global_position+Vector3.UP*1.5
	var side=forward.cross(Vector3.UP)
	var desired=focus-forward*4.6+Vector3.UP*1.3+side*1.1
	var space=viewport.world_3d.direct_space_state if viewport.world_3d else null
	if space:
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(focus,desired,1))
		if not hit.is_empty():desired=hit.position+(focus-hit.position).normalized()*.4
	camera.position=desired if dt==0. else camera.position.lerp(desired,1.-exp(-dt*3.))
	camera.look_at(focus+forward*5.)
func _exit_tree():
	# Remove only this override. Registering the shared API here rewrites its
	# RPC root to a disappearing viewport and breaks subsequent online matches.
	if not multiplayer_path.is_empty():get_tree().set_multiplayer(null,multiplayer_path)

