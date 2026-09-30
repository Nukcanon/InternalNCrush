extends SceneTree
# Button row layout of the settings-exit dialog (three buttons): positions,
# widths and any spacer between them.
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720)
	var menu_font=FontVariation.new();menu_font.base_font=load("res://assets/fonts/DoHyeon-Regular.ttf");menu_font.fallbacks=[UiSkin.symbol_font(),load("res://assets/Korean.ttf")]
	var theme=UiSkin.build(menu_font,false)
	var dialog=ConfirmationDialog.new();root.add_child(dialog)
	dialog.title="설정 변경";dialog.dialog_text="화면·그래픽 설정이 변경되었습니다. 적용하고 나갈까요?"
	dialog.ok_button_text="적용하고 나가기";dialog.cancel_button_text="계속 설정"
	dialog.add_button("적용하지 않고 나가기",false,"discard")
	DialogStyle.apply(dialog,theme);DialogStyle.popup(dialog)
	for i in range(4):await process_frame
	var row=dialog.get_ok_button().get_parent()
	print("ROW ",row.get_class()," size ",row.size," alignment ",row.alignment," sep ",row.get_theme_constant("separation"))
	for c in row.get_children():
		print("  ",c.name," ",c.get_class()," visible=",c.visible," pos=",c.position," size=",c.size," min=",c.custom_minimum_size," flags=",c.size_flags_horizontal if c is Control else "-"," text=",c.text if c is Button else "")
	root.get_texture().get_image().save_png("res://../validation/hands2/dialog_row.png")
	quit()
