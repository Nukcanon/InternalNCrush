extends SceneTree
# Which UI symbols each font can draw, and how the menu / HUD themes render them.
const SAMPLE="가운데점 · 테스트 ◆ BLUE ● ORANGE ∞ − × ≥ … → ✓ ⚠ ★ ° ㆍ ‥ / | ~ %"
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1400,400);DisplayServer.window_set_size(root.size)
	var fonts={"Rajdhani":load("res://assets/fonts/Rajdhani-SemiBold.ttf"),"DoHyeon":load("res://assets/fonts/DoHyeon-Regular.ttf"),"Korean":load("res://assets/Korean.ttf")}
	for name in fonts:
		var f:Font=fonts[name];var missing=[]
		for ch in SAMPLE:
			if ch==" ":continue
			if not f.has_char(ch.unicode_at(0)):missing.append("%s(U+%04X)"%[ch,ch.unicode_at(0)])
		print(name," missing: ",", ".join(missing))
	var ui=load("res://scripts/ui_skin.gd")
	var menu_font=FontVariation.new();menu_font.base_font=fonts.DoHyeon;menu_font.fallbacks=[fonts.Korean]
	var menu_theme=ui.build(menu_font,false)
	var hud_font=FontVariation.new();hud_font.base_font=fonts.Rajdhani;hud_font.fallbacks=[fonts.DoHyeon,fonts.Korean]
	for source_font in [hud_font.base_font]+hud_font.fallbacks:source_font.multichannel_signed_distance_field=true;source_font.msdf_size=96
	var bg=ColorRect.new();bg.color=Color("f3ecd8");bg.size=Vector2(1400,400);root.add_child(bg)
	var box=VBoxContainer.new();box.position=Vector2(20,20);root.add_child(box)
	var a=Label.new();a.theme=menu_theme;a.text="MENU  "+SAMPLE;a.add_theme_font_size_override("font_size",30);box.add_child(a)
	var b=Label.new();b.text="HUD   "+SAMPLE;b.add_theme_font_override("font",hud_font);b.add_theme_font_size_override("font_size",30);b.add_theme_color_override("font_color",Color.BLACK);box.add_child(b)
	var c=Button.new();c.theme=menu_theme;c.text="다음 · 경기 시작 ◆ 확인";box.add_child(c)
	var d=Label.new();d.text="KOREAN "+SAMPLE;d.add_theme_font_override("font",fonts.Korean);d.add_theme_font_size_override("font_size",30);d.add_theme_color_override("font_color",Color.BLACK);box.add_child(d)
	var e=Label.new();e.text="DOHYEON "+SAMPLE;e.add_theme_font_override("font",fonts.DoHyeon);e.add_theme_font_size_override("font_size",30);e.add_theme_color_override("font_color",Color.BLACK);box.add_child(e)
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/glyphs.png");print("GLYPHS_OK");quit()
