extends SceneTree
## 1.4 screen coverage: every menu and confirmation at desktop resolutions
## (16:9, 16:10, 4:3, ultrawide, 4K) and phone/tablet screens (touch layout).
## Checks: panels and dialogs stay on screen, dialogs stay compact, captions
## fit their buttons at a readable size, and no script errors occur.
const DESKTOP=[Vector2i(1280,720),Vector2i(1366,768),Vector2i(1920,1080),Vector2i(1920,1200),Vector2i(1024,768),Vector2i(2560,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
const TOUCH=[Vector2i(2400,1080),Vector2i(1600,720),Vector2i(1280,720),Vector2i(2048,1536)]
var checks=0
var failures=0
var g:Node
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func screen_rect(control:Control) -> Rect2:
	var xf:Transform2D=control.get_global_transform_with_canvas()
	return xf*Rect2(Vector2.ZERO,control.size)
func check_panel(label:String,view:Rect2):
	var panel:Control=g.ui.panel
	if not is_instance_valid(panel):expect(false,label+" has a panel");return
	var r=screen_rect(panel)
	expect(view.grow(2.).encloses(r),"%s panel on screen %s in %s"%[label,r,view])
	# Proportions: the panel is never stretched along one axis.
	var xf:Transform2D=panel.get_global_transform_with_canvas()
	expect(absf(xf.get_scale().x-xf.get_scale().y)<.01,"%s panel keeps its proportions %s"%[label,xf.get_scale()])
	check_buttons(label,panel,view)
func check_buttons(label:String,parent:Node,view:Rect2):
	var touch=TouchControls.supported()
	for b in parent.find_children("*","Button",true,false):
		if not b.is_visible_in_tree() or b.text.is_empty() or b is OptionButton:continue
		var size=b.get_theme_font_size("font_size")
		expect(size>=(14 if touch else 11),"%s '%s' readable font (%d)"%[label,b.text,size])
		var width=b.get_theme_font("font").get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		expect(width<=b.size.x+1.,"%s '%s' caption fits (%.0f > %.0f)"%[label,b.text,width,b.size.x])
func check_dialog(label:String,view:Rect2):
	await process_frame;await process_frame
	var dialog:AcceptDialog=null
	for w in root.find_children("*","AcceptDialog",true,false):
		if w.visible:dialog=w
	if dialog==null:expect(false,label+" dialog shown");return
	var r=Rect2(Vector2(dialog.position),Vector2(dialog.size))
	expect(view.grow(2.).encloses(r),"%s dialog on screen %s in %s"%[label,r,view])
	expect(r.size.x<=view.size.x*.75,"%s dialog compact (%.0f of %.0f)"%[label,r.size.x,view.size.x])
	for b in dialog.get_ok_button().get_parent().get_children():
		if b is Button and b.visible:
			var size=b.get_theme_font_size("font_size")
			var width=b.get_theme_font("font").get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
			expect(width<=b.size.x+1.,"%s dialog '%s' caption fits"%[label,b.text])
			expect(size>=16,"%s dialog '%s' readable (%d)"%[label,b.text,size])
	dialog.hide();dialog.canceled.emit()
	await process_frame
func screens(tag:String,resolution:Vector2i):
	# The game renders UI at native resolution (Game.apply_display_settings).
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO
	root.size=resolution;await process_frame;await process_frame
	g.ui.scale_interface()
	var view=Rect2(Vector2.ZERO,Vector2(resolution))
	var ui=g.ui
	var label="%s %dx%d"%[tag,resolution.x,resolution.y]
	ui.menu();await process_frame;check_panel(label+" main",view)
	ui.settings();await process_frame;check_panel(label+" settings",view)
	ui.practice_menu();await process_frame;check_panel(label+" bot battle",view)
	ui.confirm_navigation(func():pass,"메인메뉴");await check_dialog(label+" move",view)
	ui.host_settings();await process_frame;check_panel(label+" host",view)
	ui.training_menu();await process_frame;check_panel(label+" training",view)
	ui.internet_menu(false);await process_frame;check_panel(label+" online lobby",view)
	if not OS.has_feature("web"):
		ui.join_menu();await process_frame;check_panel(label+" LAN lobby",view);g.stop_room_search()
	ui.bot_setup=true;ui.bot_choice={"role":0,"primary":"a1","secondary":"pistol","armor_max":0,"gadget":0,"team":0};ui.gear();await process_frame;check_panel(label+" loadout",view)
	ui.bot_setup=false;ui.menu();await process_frame
	ui.confirm_practice();await check_dialog(label+" practice",view)
	ui.settings();await process_frame
	g.profile.graphics_quality=(int(g.profile.get("graphics_quality",1))+1)%3
	SettingsGuard.confirm_exit(ui,func():return {},func():pass);await check_dialog(label+" settings change",view)
	ui.menu()
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	TouchControls.supported_cache=0
	for resolution in DESKTOP:await screens("desktop",resolution)
	TouchControls.supported_cache=1
	for resolution in TOUCH:await screens("touch",resolution)
	TouchControls.supported_cache=0
	g.free();await process_frame
	print("SCREENS_V14_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
