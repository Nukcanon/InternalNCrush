extends SceneTree
## Button caption centring audit (1.4.2). For every visible button with a
## caption on the menu, lobby and loadout screens (desktop 1280x720 and a
## 2400x1080 phone) it renders the screen twice — with the captions and with
## them transparent — and takes the caption's real pixels from the difference.
## The caption's box is compared with the button face (the stylebox without its
## border, so the raised bottom edge does not count as face).
## Output: AUDIT_BUTTON lines (offsets in px) and validation/button-text/*.png
## crops of the worst buttons. Args: "all" prints every button.
const OUT="res://../validation/button-text/"
const COLORS=["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color","font_disabled_color","font_outline_color"]
var g:Node
var worst=[]
var verbose=false
var failures=0
var total=0
func _initialize():call_deferred("run")
func capture() -> Image:
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func face_rect(b:Button) -> Rect2:
	var xf:Transform2D=b.get_global_transform_with_canvas()
	var state="disabled" if b.disabled else "pressed" if b.button_pressed else "normal"
	var box:StyleBox=b.get_theme_stylebox(state)
	var r=Rect2(Vector2.ZERO,b.size)
	if box is StyleBoxFlat:
		r=r.grow_individual(-box.border_width_left,-box.border_width_top,-box.border_width_right,-box.border_width_bottom)
	return xf*r
func buttons() -> Array:
	var out=[]
	for b in root.find_children("*","Button",true,false):
		if b.is_queued_for_deletion() or not b.is_visible_in_tree() or b.text.strip_edges().is_empty():continue
		if b is OptionButton or b is CheckBox or b is CheckButton:continue
		out.append(b)
	return out
func clipped(b:Button) -> bool:
	# Buttons partly scrolled out of a ScrollContainer are cut off on purpose.
	var n=b.get_parent()
	while n!=null:
		if n is ScrollContainer:
			var outer=Rect2(n.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,n.size))
			var mine=Rect2(b.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,b.size))
			return not outer.grow(1.).encloses(mine)
		n=n.get_parent()
	return false
# 1.4.2: every button and dropdown on these screens wears the menu skin (ink
# outline, raised bottom edge); the dark 1.3 face is reported as OLDSTYLE.
var old_style=0
func skinned(b:Button) -> bool:
	var box=b.get_theme_stylebox("normal")
	if box is StyleBoxEmpty or box is StyleBoxTexture:return true # icon / card buttons draw their own face
	return box is StyleBoxFlat and box.border_color.is_equal_approx(UiSkin.INK) and box.border_width_bottom>=4
func audit(tag:String):
	# Let the previous screen's panels finish freeing before collecting buttons.
	for i in range(3):await process_frame
	var a:Image=await capture()
	a.save_png(OUT+"screen-"+tag.replace(" ","_")+".png")
	for b in root.find_children("*","Button",true,false):
		if b.is_queued_for_deletion() or not b.is_visible_in_tree() or b is CheckBox or b is CheckButton:continue
		if b.get_parent() is TabBar or str(b.get_path()).contains("TouchControls"):continue
		if not skinned(b):
			old_style+=1;print("AUDIT_BUTTON OLDSTYLE %s '%s' %s"%[tag,b.text,b.get_path()])
	var list=buttons()
	if list.is_empty():return
	var saved={}
	for b in list:
		saved[b]={}
		for key in COLORS:
			saved[b][key]=b.get_theme_color(key) if b.has_theme_color_override(key) else null
			b.add_theme_color_override(key,Color(0,0,0,0))
	var c:Image=await capture()
	list=list.filter(func(b):return is_instance_valid(b))
	for b in list:
		for key in COLORS:
			if saved[b][key]==null:b.remove_theme_color_override(key)
			else:b.add_theme_color_override(key,saved[b][key])
	var size=a.get_size()
	for b in list:
		var face=face_rect(b);var r=Rect2i(face.position.floor(),face.size.ceil()).intersection(Rect2i(Vector2i.ZERO,size))
		if r.size.x<4 or r.size.y<4 or clipped(b):continue
		# A caption that cannot fit (font shrunk to nothing, button squeezed) is a defect of its own.
		var fs=b.get_theme_font_size("font_size")
		var need=b.get_theme_font("font").get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		if fs<11 or need>face.size.x+2.:
			failures+=1;total+=1
			print("AUDIT_BUTTON BAD %s '%s' squeezed: font=%d caption=%.0f face=%dx%d %s"%[tag,b.text,fs,need,face.size.x,face.size.y,b.get_path()])
			continue
		var lo=Vector2i(1<<30,1<<30);var hi=Vector2i(-1,-1)
		for y in range(r.position.y,r.end.y):
			for x in range(r.position.x,r.end.x):
				var p=a.get_pixel(x,y);var q=c.get_pixel(x,y)
				if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>.25:
					lo=Vector2i(mini(lo.x,x),mini(lo.y,y));hi=Vector2i(maxi(hi.x,x),maxi(hi.y,y))
		if hi.x<0:continue
		total+=1
		var text_centre=Vector2(lo+hi)*.5+Vector2(.5,.5);var face_centre=face.get_center()
		var d=text_centre-face_centre
		# Captions left-aligned on purpose stay out of the horizontal check.
		var dx=d.x if b.alignment==HORIZONTAL_ALIGNMENT_CENTER else 0.
		var bad=absf(d.y)>maxf(1.6,face.size.y*.05) or absf(dx)>maxf(3.,face.size.x*.03)
		if bad:failures+=1
		if bad or verbose:
			print("AUDIT_BUTTON %s %s '%s' dx=%.1f dy=%.1f face=%dx%d text=%dx%d font=%d %s"%["BAD" if bad else "ok",tag,b.text.replace("\n"," / "),dx,d.y,face.size.x,face.size.y,hi.x-lo.x+1,hi.y-lo.y+1,b.get_theme_font_size("font_size"),b.get_path()])
		if bad:
			worst.append([absf(d.y)+absf(dx)*.5,tag,b.text,a.get_region(Rect2i(r.position-Vector2i(6,6),r.size+Vector2i(12,12)).intersection(Rect2i(Vector2i.ZERO,size)))])
func run():
	verbose="all" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(OUT)
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	for setup in [["desktop",Vector2i(1280,720),0],["phone",Vector2i(2400,1080),1]]:
		TouchControls.supported_cache=setup[2]
		root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO
		root.size=setup[1];DisplayServer.window_set_size(setup[1])
		for i in range(4):await process_frame
		g.ui.scale_interface()
		var ui=g.ui;var t=setup[0]
		ui.menu();await audit(t+" menu")
		ui.settings();await audit(t+" settings")
		ui.practice_menu();await audit(t+" bot-battle")
		ui.host_settings();await audit(t+" host")
		ui.training_menu();await audit(t+" training")
		ui.internet_menu(false);await audit(t+" online")
		ui.bot_setup=true;ui.bot_choice={"role":0,"primary":"a1","secondary":"pistol","armor_max":0,"gadget":0,"team":0};ui.gear()
		for category in range(5):
			ui.gear_category=category;ui.refresh_gear_cards();await audit(t+" gear-%d"%category)
		ui.bot_setup=false
		# Room lobby (hosted offline) and its sub-screens.
		g.host_game(OfflineMultiplayerPeer.new());for i in range(4):await process_frame
		ui.lobby();await audit(t+" lobby")
		ui.teams_menu();await audit(t+" teams")
		ui.members_menu();await audit(t+" members")
		ui.gear();await audit(t+" lobby-gear")
		# In a match: the TAB scoreboard (results) and the pause menu.
		ui.clear_panel();g.start_match();for i in range(10):await process_frame
		ui.clear_panel();ui.scoreboard.pinned=true;ui.scoreboard.visible=true;ui.scoreboard.refresh_scores(1.)
		await audit(t+" scoreboard");ui.scoreboard.pinned=false;ui.scoreboard.visible=false
		ui.toggle_pause();await audit(t+" pause");ui.clear_panel()
		g.leave_game();for i in range(4):await process_frame
		ui.menu()
	worst.sort_custom(func(x,y):return x[0]>y[0])
	for i in range(mini(24,worst.size())):
		worst[i][3].save_png(OUT+"%02d-%s-%s.png"%[i,worst[i][1].replace(" ","_"),worst[i][2].replace(" ","").replace("/","").replace("\n","").left(12)])
	print("AUDIT_BUTTON_RESULT bad=%d of %d old_style=%d"%[failures,total,old_style])
	g.queue_free();for i in range(4):await process_frame
	quit(1 if failures>0 or old_style>0 or total<100 else 0)
