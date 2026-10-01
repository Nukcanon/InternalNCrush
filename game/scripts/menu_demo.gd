extends SubViewportContainer
## A real isolated offline match. It neither opens ENet ports nor saves a profile.
var viewport:SubViewport
var match_game:Node3D
var camera:Camera3D
var elapsed=0.
var multiplayer_path:NodePath
var render_accumulator=0.
var followed:Node3D # the bot the chase camera is on (snaps when it changes)
var lens=SphereShape3D.new() # clearance around the camera (radius set in _ready)
func _ready():
	stretch=true;stretch_shrink=1;mouse_filter=Control.MOUSE_FILTER_IGNORE
	viewport=SubViewport.new();viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;viewport.size=Vector2i(1280,720);viewport.own_world_3d=true;viewport.handle_input_locally=false;viewport.gui_disable_input=true;viewport.audio_listener_enable_3d=false;add_child(viewport)
	GraphicsOptions.apply_viewport(viewport)
	multiplayer_path=viewport.get_path();get_tree().set_multiplayer(SceneMultiplayer.new(),multiplayer_path)
	match_game=load("res://scripts/game.gd").new();match_game.demo_mode=true;viewport.add_child(match_game)
	camera=Camera3D.new();camera.fov=65.;camera.far=160.;viewport.add_child(camera);camera.current=true
	lens.radius=.3
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
	# 1.4.5: the camera was sometimes inside a wall (black view): the clear-line
	# check used the desired point only, so the smoothed camera crossed walls on
	# its way there, a bot with its back to a wall left no room behind it, and
	# props (crates, layer 8) were ignored. Now the best of several angles
	# around the bot is taken (the one with the longest clear line, behind it
	# first), the camera snaps when the followed bot changes, and the smoothed
	# position itself is kept on the clear side of anything in the way.
	# (find_world_3d: the viewport's own world; `world_3d` is only the override
	# property and was null here, so the old clear-line check never ran)
	var world:World3D=viewport.find_world_3d()
	var space:PhysicsDirectSpaceState3D=world.direct_space_state if world else null
	var desired=focus-forward*4.6+Vector3.UP*1.3+side*1.1
	if space:
		var best=-1.;var options=[-forward*4.6+side*1.1,-forward*4.6-side*1.1,(-forward+side).normalized()*4.6,(-forward-side).normalized()*4.6,side*4.6,-side*4.6,forward*4.6]
		for option in options:
			var point:Vector3=focus+option+Vector3.UP*1.3
			var clear=clear_point(space,focus,point)
			var length=focus.distance_to(clear)
			if length>best:best=length;desired=clear
			if length>=4.:break # behind the bot whenever that view is open
	var switched=actor!=followed;followed=actor
	camera.position=desired if dt==0. or switched else camera.position.lerp(desired,1.-exp(-dt*3.))
	if space:
		camera.position=clear_point(space,focus,camera.position)
		# A wall or crate beside the lens (off the line but within the near
		# plane) also pushes it in toward the bot.
		var probe=PhysicsShapeQueryParameters3D.new();probe.shape=lens;probe.collision_mask=1|8
		for step in range(6):
			probe.transform=Transform3D(Basis.IDENTITY,camera.position)
			if space.intersect_shape(probe,1).is_empty():break
			camera.position+=(focus-camera.position).normalized()*.3
	camera.look_at(focus+forward*5.)
# The point on the line focus -> point that is in front of any wall or prop
# between them, kept a camera's width clear of the hit.
func clear_point(space:PhysicsDirectSpaceState3D,focus:Vector3,point:Vector3) -> Vector3:
	var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(focus,point,1|8))
	if hit.is_empty():return point
	var back=(focus-hit.position).normalized()
	return hit.position+back*minf(.45,hit.position.distance_to(focus)*.5)
func _exit_tree():
	# Remove only this override. Registering the shared API here rewrites its
	# RPC root to a disappearing viewport and breaks subsequent online matches.
	if not multiplayer_path.is_empty():get_tree().set_multiplayer(null,multiplayer_path)

