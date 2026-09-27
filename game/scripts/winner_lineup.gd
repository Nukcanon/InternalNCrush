extends VBoxContainer
class_name WinnerLineup
var game:Node
var signature=""
func refresh():
	visible=game.phase=="result"
	if not visible:return
	var ids=[]
	for p in game.players.values():
		if (int(game.options.mode)==1 and int(p.id)==int(game.result.get("player",0))) or (int(game.options.mode)!=1 and int(p.team)==int(game.result.get("team",-1))):ids.append(p.id)
	var next=str([game.result,ids])
	if next==signature:return
	signature=next
	for child in get_children():remove_child(child);child.queue_free()
	var heading=Label.new();heading.text="무승부" if ids.is_empty() else "승리한 플레이어" if int(game.options.mode)==1 else "BLUE 승리" if int(game.result.team)==0 else "ORANGE 승리";heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_theme_font_size_override("font_size",25);add_child(heading)
	for start in range(0,ids.size(),8):
		var row=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",10);add_child(row)
		for index in range(start,mini(start+8,ids.size())):
			var p=game.players[ids[index]];var column=VBoxContainer.new();column.custom_minimum_size.x=120;row.add_child(column)
			var nick=Label.new();nick.text=p.nick;nick.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;nick.add_theme_font_size_override("font_size",14);nick.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;column.add_child(nick)
			var image=TextureRect.new();image.custom_minimum_size=Vector2(120,72);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;column.add_child(image)
			var path="res://assets/thumbnails/role%d.png"%int(p.role)
			if ResourceLoader.exists(path):image.texture=load(path)
