extends SceneTree
var g:Node
var actor:Actor
var camera:Camera3D
var clock=0.
var frame=0
var output=""
var label:Label
func _initialize():call_deferred("run")
func run():
	output=ProjectSettings.globalize_path("res://../../validation/motion");DirAccess.make_dir_recursive_absolute(output)
	g=load("res://scripts/game.gd").new();root.add_child(g);g.ui.clear_panel();g.set_physics_process(false);g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=7;g.build_world();g.add_player(1,"MOTION REVIEW","motion_review")
	actor=g.actors[1];actor.position=Vector3(0,.1,0);actor.set_local(false);g.players[1].protect=0.;g.players[1].role=0;actor.reset_view(0)
	camera=Camera3D.new();g.add_child(camera);camera.current=true;camera.fov=46.;camera.near=.1
	var layer=CanvasLayer.new();root.add_child(layer);label=Label.new();label.theme=g.ui.theme;label.position=Vector2(32,28);label.add_theme_font_size_override("font_size",25);layer.add_child(label)
	physics_frame.connect(step)
func step():
	clock+=1./60.;frame+=1
	var stage=int(clock/1.2)
	actor.input_state.x=0.;actor.input_state.z=0.;actor.input_state.sprint=false;actor.input_state.crouch=false;actor.input_state.jump=false
	match stage:
		0:label.text="IDLE / 호흡과 체중 이동"
		1:actor.input_state.z=-1.;actor.input_state.sprint=true;label.text="ACCELERATE / 출발 · 상체 기울기"
		2:actor.input_state.x=1.;actor.input_state.sprint=true;label.text="CUT RIGHT / 방향 전환 · 하체 관성"
		3:actor.input_state.x=-1.;label.text="CUT LEFT / 반대 방향 전환"
		4:label.text="BRAKE / 감속 · 정지"
		5:actor.input_state.jump=clock<6.12;label.text="JUMP / 제자리 점프와 착지"
		6:actor.input_state.crouch=true;label.text="CROUCH / 무릎 · 골반 전환"
		7:actor.input_state.crouch=true;actor.input_state.z=.5;label.text="CROUCH WALK / 낮은 자세 이동"
		8:actor.input_state.yaw=(clock-9.6)*2.;label.text="TURN / 제자리 회전 발 디딤"
		_:finish();return
	actor.simulate(1./60.,clock,true);actor.visual(1./60.,g.players[1],clock)
	var focus=actor.position+Vector3.UP*.95
	camera.position=focus+Vector3(2.,1.1,4.1);camera.look_at(focus)
	if frame%12==0:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("frame%04d.png"%frame))
func finish():
	physics_frame.disconnect(step);g.free();await process_frame;await process_frame;print("MOTION_REVIEW_DONE");quit()
