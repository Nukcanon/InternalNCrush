class_name SettingsGuard
extends RefCounted
const KEYS=["monitor","display_mode","width","height","window","graphics_auto","graphics_quality","antialias","shadow_quality","decor_quality","lighting_quality","physics_effects","corpse_quality","fog_enabled","blood_effects","menu_animation","frame_limit","web_quality","web_options","web_render_scale"]
static func snapshot(profile:Dictionary) -> Dictionary:
	var out={}
	for key in KEYS:
		if profile.has(key):out[key]=profile[key]
	return out.duplicate(true)
static func confirm_exit(ui:Node,read_display:Callable,leave:Callable):
	var proposed=snapshot(ui.game.profile);proposed.merge(read_display.call(),true)
	if proposed==ui.settings_baseline:leave.call();return
	if is_instance_valid(ui.settings_dialog):return
	var dialog=ConfirmationDialog.new();ui.settings_dialog=dialog;ui.root.add_child(dialog)
	dialog.title="변경한 설정";dialog.dialog_text="화면·그래픽 설정이 변경되었습니다. 적용하고 나갈까요?"
	dialog.ok_button_text="적용하고 나가기";dialog.cancel_button_text="계속 설정"
	dialog.add_button("적용하지 않고 나가기",false,"discard")
	dialog.confirmed.connect(func():
		ui.game.profile.merge(proposed,true);ui.game.apply_display_settings();GraphicsOptions.apply(ui.game)
		if OS.has_feature("web"):WebGraphics.apply_settings(ui.game)
		ui.game.save_profile();dialog.queue_free();leave.call())
	dialog.custom_action.connect(func(action):
		if action!="discard":return
		ui.game.profile.merge(ui.settings_baseline,true);ui.game.apply_display_settings();GraphicsOptions.apply(ui.game)
		if OS.has_feature("web"):WebGraphics.apply_settings(ui.game)
		ui.game.save_profile();dialog.queue_free();leave.call())
	dialog.canceled.connect(dialog.queue_free)
	DialogStyle.apply(dialog,ui.theme);dialog.popup_centered(Vector2i(720,180))
