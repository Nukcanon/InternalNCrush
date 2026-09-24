extends SceneTree
var checks=0
var failures=0
var g:Node
var visual=false
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
	else:print("PASS ",message)
func find_button(parent:Node,text:String) -> Button:
	for item in parent.find_children("*","Button",true,false):
		if item.text==text:return item
	return null
func settle():
	for i in range(6):await process_frame
func capture(name:String):
	await settle()
	if visual:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/v104-ui/"+name+".png")
func run():
	visual=DisplayServer.get_name()!="headless"
	DirAccess.make_dir_recursive_absolute("res://../validation/v104-ui")
	g=load("res://scripts/game.gd").new();root.add_child(g)
	var ui=g.ui
	await capture("main")
	for text in ["내부망 로비","인터넷 로비","봇 전투","연습장"]:expect(find_button(ui.panel,text)!=null,"main menu direct action "+text)
	var background=ui.background
	var live=background.get_child(0) if visual else null
	var live_clock=live.match_game.clock if visual else 0.
	find_button(ui.panel,"내부망 로비").pressed.emit();await settle()
	expect(ui.screen=="join" and ui.background==background,"LAN submenu preserves live backdrop")
	var lan=ui.lan_lobby
	expect(ui.panel.get_global_rect().position.y>=0 and ui.panel.get_global_rect().end.y<=720,"LAN window and its footer fit the logical viewport")
	expect(lan.cancel_button.disabled,"cancel unavailable without a connection attempt")
	expect(ui.panel.find_children("*","LineEdit",true,false).is_empty(),"IP fields do not consume room list space")
	expect(lan.room_scroll.size.y>=280,"room list has a large independent scrolling region")
	var footer_position=lan.actions.global_position
	for i in range(18):g.rooms["192.168.0.%d"%(10+i)]={"name":"훈련 %02d · INTERNAL N CRUSH"%i,"count":i%7,"max":8,"mode":"팀 데스매치","version":Rules.VERSION,"locked":i==0}
	g.rooms["192.168.0.28"]={"name":"구 버전","count":1,"max":8,"version":"old"}
	g.rooms["192.168.0.29"]={"name":"가득 찬 방","count":8,"max":8,"version":Rules.VERSION}
	ui.update_rooms();g.stop_room_search();await settle()
	expect(find_button(ui.room_list,"버전 다름").disabled,"incompatible rooms cannot be joined")
	expect(find_button(ui.room_list,"정원 초과").disabled,"full rooms cannot be joined")
	lan.room_scroll.scroll_vertical=200;await settle()
	expect(lan.actions.global_position.is_equal_approx(footer_position),"bottom actions remain pinned while rooms scroll")
	await capture("lan")
	lan.ip_button.pressed.emit();await settle()
	expect(is_instance_valid(lan.dialog) and lan.password.secret,"direct connection modal has masked password")
	lan.address.text="invalid-ip";lan.connect_button.pressed.emit()
	expect(not g.connection_busy and lan.dialog_notice.text.contains("올바른"),"invalid IP is rejected before connecting")
	lan.address.text="127.0.0.2";lan.password.text="ui-test";lan.connect_button.pressed.emit();await settle()
	expect(g.connection_busy and not lan.cancel_button.disabled and lan.connect_button.disabled,"pending connection exposes cancellation and prevents double submit")
	expect(g.options.password=="ui-test","modal forwards the supplied room password")
	await capture("direct")
	find_button(lan.dialog,"돌아가기").pressed.emit();await settle()
	expect(is_instance_valid(ui.navigation_confirm),"direct back asks before leaving")
	ui.navigation_confirm.confirmed.emit();await settle()
	expect(not g.connection_busy and ui.screen=="join" and not is_instance_valid(lan.dialog),"modal back cancels transport and stays in LAN lobby")
	lan.show_direct();lan.address.text="127.0.0.2";lan.submit_direct()
	g.connection_deadline=Time.get_ticks_msec()-1;g.connection_watchdog();await settle()
	expect(not g.connection_busy and ui.screen=="join" and ui.notice_label.text.contains("초과"),"timeout returns to LAN lobby with actionable error")
	lan.create_button.pressed.emit();await settle()
	expect(ui.screen=="host","accent create action opens actual host settings")
	find_button(ui.panel,"돌아가기").pressed.emit();await settle()
	expect(is_instance_valid(ui.navigation_confirm),"host back asks before leaving")
	ui.navigation_confirm.confirmed.emit();await settle()
	expect(ui.screen=="join","host settings returns to LAN lobby")
	find_button(ui.panel,"메인메뉴").pressed.emit();await settle()
	expect(is_instance_valid(ui.navigation_confirm),"LAN main menu asks before leaving")
	ui.navigation_confirm.canceled.emit();await settle()
	expect(ui.screen=="join","canceling navigation keeps LAN lobby open")
	find_button(ui.panel,"메인메뉴").pressed.emit();ui.navigation_confirm.confirmed.emit();await settle()
	expect(ui.screen=="menu" and ui.background==background,"LAN back returns to the same main backdrop")
	if visual:expect(live.match_game.clock>live_clock,"background bots continued simulating throughout menus")
	ui.practice_menu();await settle()
	var practice_footer=find_button(ui.panel,"연습 시작").get_parent()
	expect(practice_footer.get_parent()==ui.panel_body,"practice start stays outside scroll")
	var toggle:CheckBox=ui.panel.find_children("*","CheckBox",true,false)[0]
	var toggle_rect=toggle.get_global_rect();var initial_min=toggle.get_combined_minimum_size()
	for i in range(8):toggle.button_pressed=not toggle.button_pressed;await settle()
	expect(toggle.get_global_rect().is_equal_approx(toggle_rect) and toggle.get_combined_minimum_size()==initial_min,"map rotation checkbox never shifts between states")
	find_button(ui.panel,"메인메뉴").pressed.emit();expect(is_instance_valid(ui.navigation_confirm),"practice main menu asks before leaving");ui.navigation_confirm.confirmed.emit();await settle()
	ui.internet_menu();await settle()
	expect(find_button(ui.panel,"메인메뉴").get_parent().get_parent()==ui.panel_body,"internet navigation stays outside scroll")
	find_button(ui.panel,"메인메뉴").pressed.emit();expect(is_instance_valid(ui.navigation_confirm),"internet main menu asks before leaving");ui.navigation_confirm.confirmed.emit();await settle()
	ui.settings();await settle()
	var mode=ui.panel.find_child("DisplayMode",true,false)
	var resolution=ui.panel.find_child("ResolutionChoices",true,false)
	var manual=ui.panel.find_child("CustomResolution",true,false)
	for index in [0,1,2]:
		mode.select(index);mode.item_selected.emit(index)
		expect(not resolution.disabled,"resolution remains selectable for display mode "+str(index))
		resolution.select(resolution.item_count-1);resolution.item_selected.emit(resolution.selected)
		expect(manual.visible,"custom input visible only on explicit selection, mode "+str(index))
		resolution.select(0);resolution.item_selected.emit(0);expect(not manual.visible,"preset hides custom input")
	await capture("display")
	var tabs=ui.panel.find_children("*","TabContainer",true,false)[0];tabs.current_tab=1
	await capture("graphics")
	tabs.current_tab=2;await capture("hud-settings")
	for quality in [0,1,2]:
		g.profile.decor_quality=quality;g.profile.shadow_quality=quality;g.profile.antialias=quality;GraphicsOptions.apply(g)
		var burst=BurstVisual.new();g.add_child(burst);burst.build(true)
		expect(burst.puffs.size()==24 and burst.puffs.filter(func(p):return p.flame).size()==7,"quality %d preserves full fire/smoke explosion signal"%quality)
		expect(burst.find_children("*","RigidBody3D",true,false).size()==[4,8,12][quality],"quality %d reduces only decorative debris"%quality)
		burst.free();await settle()
	g.profile.decor_quality=2;g.profile.shadow_quality=2;g.profile.antialias=1;GraphicsOptions.apply(g)
	g.ui.menu();g.ui.clear_panel();g.free();await settle()
	print("LOBBY_MENU_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
