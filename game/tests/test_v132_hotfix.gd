extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	for i in range(4):await process_frame
	g.ui.settings()
	for tabs in g.ui.panel.find_children("*","TabContainer",true,false):tabs.current_tab=3
	for i in range(4):await process_frame
	var previews=[]
	for b in g.ui.panel.find_children("*","Button",true,false):
		if b.text.ends_with("듣기"):previews.append(b)
	expect(previews.size()==3,"only three audio previews")
	for b in previews:
		expect(b.get_parent() is HBoxContainer and b.size.x>100,"preview equal-width row: "+b.text)
		var siblings=b.get_parent().get_children();expect(b.get_index()>=siblings.size()-3,"previews at end of sound tab")
	g.ui.confirm_navigation(func():pass,"메인메뉴")
	await process_frame
	var dialog=g.ui.navigation_confirm;var stay=dialog.get_cancel_button();var leave=dialog.get_ok_button()
	expect(stay.get_index()<leave.get_index(),"stay left, leave right")
	expect(stay.get_theme_stylebox("normal").bg_color==Color("285a43"),"stay green")
	expect(leave.get_theme_stylebox("normal").bg_color==Color("593b4b"),"leave red")
	dialog.canceled.emit();await process_frame
	var scroll=load("res://scripts/menu_touch_scroll.gd").new();root.add_child(scroll);scroll.position=Vector2(30,30);scroll.size=Vector2(200,150)
	var content=Control.new();content.custom_minimum_size=Vector2(170,900);scroll.add_child(content)
	for i in range(3):await process_frame
	var press=InputEventScreenTouch.new();press.index=2;press.pressed=true;press.position=Vector2(100,130);scroll._input(press)
	var drag=InputEventScreenDrag.new();drag.index=2;drag.position=Vector2(100,50);scroll._input(drag)
	expect(scroll.scroll_vertical>=75,"real touch swipe scrolls menu")
	press.pressed=false;scroll._input(press);expect(scroll.finger==-1 and not scroll.dragging,"touch release resets drag")
	scroll.queue_free()
	Catalog.load_all();var w=WeaponVisual.new();root.add_child(w);w.build(Catalog.get_weapon("h5"),true)
	var sockets=[]
	for slot in range(4):
		w.reload_tube=slot;w.animate_reload(.72,0.);sockets.append(Vector2(w.reload_round.position.x,w.reload_round.position.y))
	expect(sockets[0]!=sockets[1] and sockets[0]!=sockets[2] and sockets[2]!=sockets[3],"QUAD reload visits four tubes")
	var nose=w.reload_round.get_child(2)
	expect((nose.transform.basis*Vector3.UP).z<-.99,"rocket nose points forward into breech")
	w.queue_free()
	expect(LaserCombat.dps(0.)==60. and LaserCombat.dps(.98)==120.,"final ARC 60 to 120 DPS")
	g.leave_game()
	for i in range(4):await process_frame
	g.queue_free();await process_frame;await process_frame
	print("HOTFIX_RESULT ",checks," checks / ",failures," failures");quit(1 if failures else 0)
