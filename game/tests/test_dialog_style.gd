extends SceneTree
var failed=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	if not ok:failed+=1;printerr("FAIL ",message)
func run():
	for navigation in [false,true]:
		var dialog=ConfirmationDialog.new();root.add_child(dialog)
		dialog.ok_button_text="이동하기" if navigation else "적용하고 나가기"
		dialog.cancel_button_text="계속 머물기" if navigation else "취소"
		DialogStyle.apply(dialog,Theme.new(),navigation);dialog.popup_centered(Vector2i(600,200))
		await process_frame;await process_frame
		var ok=dialog.get_ok_button();var cancel=dialog.get_cancel_button()
		check(ok.position.x>cancel.position.x,"affirmative is on right")
		check(absf(ok.size.x-cancel.size.x)<1. and ok.size.y==cancel.size.y,"matching button dimensions")
		check(ok.get_theme_stylebox("normal").bg_color==(UiSkin.STOP if navigation else UiSkin.GO),"correct affirmative color")
		# 1.3.3: in navigation prompts "stay" is the safe, green choice; leaving is red.
		check(cancel.get_theme_stylebox("normal").bg_color==(UiSkin.GO if navigation else UiSkin.STOP),"negative is red, navigation stay is green")
		dialog.free()
	print("DIALOG_STYLE 8 checks / ",failed," failures");quit(1 if failed else 0)
