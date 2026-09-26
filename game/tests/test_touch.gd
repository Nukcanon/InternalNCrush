extends SceneTree
var game:Node
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func touch(id:int,point:Vector2,pressed:bool):
	var event=InputEventScreenTouch.new();event.index=id;event.position=game.ui.root.get_global_transform_with_canvas()*point;event.pressed=pressed;game.touch._input(event)
func drag(id:int,point:Vector2,delta:Vector2):
	var event=InputEventScreenDrag.new();event.index=id;event.position=game.ui.root.get_global_transform_with_canvas()*point;event.relative=game.ui.root.get_global_transform_with_canvas().basis_xform(delta);game.touch._input(event)
func capture(name:String):
	if DisplayServer.get_name()=="headless":return
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://../validation/v11-touch")
	root.get_texture().get_image().save_png("res://../validation/v11-touch/"+name+".png")
func run():
	game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
	expect(is_instance_valid(game.touch),"touch feature creates dedicated overlay")
	expect(not game.touch.active(),"touch sticks hidden in menus")
	game.capture_pointer();expect(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"touch never requests desktop pointer lock")
	await capture("menu")
	game.ui.confirm_practice();expect(game.ui.navigation_confirm.dialog_text=="연습장으로 이동하시겠습니까?","practice asks before entering")
	game.ui.navigation_confirm.confirmed.emit();game.set_physics_process(false);game.touch._process(0)
	var a:Actor=game.actors[1];game.players[1].protect=0.;game.clock=100.
	touch(0,Vector2(165,500),true);drag(0,Vector2(165,410),Vector2(0,-90))
	touch(1,Vector2(1165,465),true);touch(2,Vector2(880,310),true);drag(2,Vector2(930,290),Vector2(50,-20))
	game.collect_input()
	expect(a.input_state.z<-.9 and a.input_state.fire and not a.input_state.sprint,"stick edge moves without involuntary sprint")
	touch(7,Vector2(120,380),true);touch(7,Vector2(120,380),false);game.collect_input()
	expect(a.input_state.sprint,"sprint button stays toggled after release")
	touch(7,Vector2(120,380),true);touch(7,Vector2(120,380),false);game.collect_input()
	expect(not a.input_state.sprint,"second sprint tap stops sprinting")
	expect(a.input_state.yaw<0 and a.input_state.pitch>0,"independent aim drag while moving/firing")
	var before_yaw=float(a.input_state.yaw)
	drag(0,Vector2(170,410),Vector2(-700,800))
	drag(2,Vector2(940,290),Vector2(-880,540))
	expect(absf(a.input_state.yaw-before_yaw+.028)<.0001,"cross-finger relative corruption does not affect aim")
	before_yaw=float(a.input_state.yaw)
	drag(9,Vector2(800,200),Vector2(999,999))
	expect(a.input_state.yaw==before_yaw,"unowned drag cannot steer camera")
	touch(2,Vector2(940,290),false);touch(2,Vector2(860,300),true)
	drag(2,Vector2(865,300),Vector2(2000,2000))
	expect(absf(a.input_state.yaw-before_yaw+.014)<.0001,"reused contact starts at its own new press position")
	var seq=a.input_state.trigger_seq;touch(1,Vector2(1165,465),false);game.collect_input()
	expect(not a.input_state.fire and a.input_state.z<-.9,"releasing fire keeps the movement finger")
	touch(1,Vector2(1165,465),true);game.collect_input();expect(a.input_state.trigger_seq==seq+1,"semi-auto touch taps use a fresh trigger sequence")
	touch(0,Vector2(165,410),false);touch(1,Vector2(1165,465),false);touch(2,Vector2(930,290),false)
	game.collect_input();expect(a.input_state.x==0 and a.input_state.z==0 and not a.input_state.fire,"all releases clear held inputs")
	touch(6,Vector2(1020,450),true);touch(6,Vector2(1020,450),false);game.collect_input()
	expect(a.input_state.ads,"ADS stays toggled after releasing touch")
	touch(6,Vector2(1020,450),true);touch(6,Vector2(1020,450),false);game.collect_input()
	expect(not a.input_state.ads,"second ADS tap releases aiming")
	touch(6,Vector2(1190,680),true);touch(6,Vector2(1190,680),false);game.collect_input()
	expect(a.input_state.crouch,"crouch stays toggled without a held finger")
	touch(6,Vector2(1190,680),true);touch(6,Vector2(1190,680),false);game.collect_input()
	expect(not a.input_state.crouch,"second crouch tap stands up")
	game.players[1].reload=game.clock+2.;game.touch.held.ads=true
	touch(6,Vector2(1020,450),true);touch(6,Vector2(1020,450),false);game.collect_input()
	expect(not a.input_state.ads,"an unavailable ADS toggle can still be switched off")
	game.players[1].reload=0.
	game.touch.redraw_timer=0.;game.touch._process(0.)
	expect(not game.touch.buttons.has("bomb"),"practice has no misleading bomb installation button")
	game.options.mode=4;game.touch.redraw_timer=0.;game.touch._process(0.)
	expect(game.touch.buttons.has("bomb") and not ActionState.available(game,1,"bomb"),"bomb button appears only for bomb mode and is grey without a valid action")
	game.options.mode=0
	game.touch.held.auto_fire=false;game.profile.touch_auto_fire=false;game.touch.press("auto_fire",true);game.touch.press("auto_fire",false)
	expect(game.profile.touch_auto_fire,"auto fire can be enabled without holding the trigger")
	game.profile.touch_auto_fire=false
	game.ui.notice_until=0;game.ui.practice_hint_until=Time.get_ticks_msec()+1000;game.ui.refresh()
	expect(not game.ui.banner.text.is_empty(),"practice welcome hint is initially visible")
	game.ui.practice_hint_until=0;game.ui.refresh();expect(game.ui.banner.text.is_empty(),"practice welcome hint expires")
	for scale in [.65,.8,1.1]:
		game.profile.hud_scale=scale;HudLayout.apply(game.ui)
		expect(game.ui.hud.get_node("Hud_ammo").position.y>=145.,"mobile ammunition stays below the single kill row at every scale")
	var feed=[]
	for i in range(3):feed.append({"serial":i,"received":Time.get_ticks_msec(),"attacker":1,"victim":2,"attacker_team":0,"victim_team":1,"attacker_name":"A","victim_name":"B","weapon":"a1"})
	game.ui.kill_feed.refresh(feed,1,Time.get_ticks_msec());expect(game.ui.kill_feed.get_child_count()==1,"mobile kill feed shows only the most recent kill")
	game.players[1].mag[game.players[1].primary]=0
	touch(6,Vector2(1050,590),true);touch(6,Vector2(1050,590),false)
	expect(float(game.players[1].reload)>game.clock,"reload button begins a real weapon reload")
	game.players[1].reload=0.
	touch(6,Vector2(1040,45),true);game.ui.refresh()
	expect(game.ui.scoreboard.visible,"record button displays the scoreboard")
	touch(6,Vector2(1040,45),false);game.ui.refresh()
	expect(not game.ui.scoreboard.visible,"releasing record hides the scoreboard")
	for frame in range(5):a.visual(.016,game.players[1],game.clock)
	game.ui.refresh();await capture("hud")
	touch(3,Vector2(570,670),true);touch(3,Vector2(570,670),false)
	expect(game.players[1].slot==1,"touch weapon tile switches secondary")
	game.players[1].fire_ready=0.;game.players[1].melee_ready=0.;game.players[1].placing="";game.players[1].cooking=0;game.players[1].protect=0.
	expect(game.touch.buttons.has("melee") and not game.touch.buttons.has("slot4"),"mobile adds only one melee button and no fifth slot")
	touch(7,Vector2(1028,524),true);touch(7,Vector2(1028,524),false)
	expect(game.players[1].melee_started==game.clock and game.players[1].slot==1,"touch quick melee swings without switching the selected gun")
	expect(not ActionState.available(game,1,"melee"),"mobile melee greys out during cooldown")
	for notification in [Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT,Node.NOTIFICATION_APPLICATION_FOCUS_OUT]:
		touch(4,Vector2(1165,465),true);touch(0,Vector2(165,500),true);drag(0,Vector2(165,410),Vector2(0,-90))
		game.touch.notification(notification);game.collect_input()
		expect(not a.input_state.fire and a.input_state.z==0 and game.touch.fingers.is_empty(),"focus loss releases held movement and fire (%d)"%notification)
	touch(4,Vector2(1165,465),true);touch(5,Vector2(1180,45),true);game.touch._process(0);game.collect_input()
	expect(is_instance_valid(game.ui.panel) and not a.input_state.fire and game.touch.fingers.is_empty(),"opening pause clears held touch fire")
	await capture("pause")
	game.leave_game();game.free();await process_frame
	print("TOUCH_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
