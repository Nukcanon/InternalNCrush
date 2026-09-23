extends VBoxContainer
class_name KillFeed
const MAX_ROWS=6
const LIFETIME_MS=6500
const BLUE=Color("6bc7ff")
const ORANGE=Color("ffa35f")
var signature=""
static func team_color(team:int) -> Color:
	return BLUE if team==0 else ORANGE if team==1 else Color("c1cdd4")
static func compact_name(value:String) -> String:
	var split=value.rfind(" #")
	var suffix=value.substr(split) if split>=0 else ""
	var base=value.left(split) if split>=0 else value
	return (base.left(8)+"…" if base.length()>10 else base)+suffix
func _ready():
	position=Vector2(949,78);custom_minimum_size.x=425;scale=Vector2(.72,.72);mouse_filter=Control.MOUSE_FILTER_IGNORE;add_theme_constant_override("separation",5)
func refresh(events:Array,local_id:int,now:int):
	var visible_events=events.filter(func(event):return now-int(event.received)<LIFETIME_MS)
	var next=""
	for event in visible_events:next+=str(event.serial)+"/"
	if next==signature:return
	signature=next
	for child in get_children():remove_child(child);child.queue_free()
	for event in visible_events:
		var panel=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
		var style=StyleBoxFlat.new();style.bg_color=Color(.035,.075,.10,.48);style.set_corner_radius_all(6);style.set_content_margin_all(3)
		if local_id in [int(event.attacker),int(event.victim)]:style.border_color=team_color(int(event.attacker_team));style.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel",style)
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",5);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(row)
		name_label(row,str(event.attacker_name),int(event.attacker_team),HORIZONTAL_ALIGNMENT_RIGHT)
		var glyph=WeaponGlyph.new();glyph.weapon=str(event.weapon);glyph.tooltip_text=Catalog.get_weapon(event.weapon).get("name",event.weapon) if Catalog.weapons.has(event.weapon) else "포탑" if event.weapon=="turret" else "환경";row.add_child(glyph)
		name_label(row,str(event.victim_name),int(event.victim_team),HORIZONTAL_ALIGNMENT_LEFT)
func name_label(parent:Node,value:String,team:int,alignment:int):
	var label=Label.new();label.text=compact_name(value);label.tooltip_text=value;label.horizontal_alignment=alignment;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.custom_minimum_size.x=145;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.add_theme_font_size_override("font_size",17);label.add_theme_color_override("font_color",team_color(team));label.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(label)
