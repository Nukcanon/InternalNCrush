class_name HudLayout
extends RefCounted
const ORIGINS={"health":Vector2(22,595),"ammo":Vector2(995,577),"gear":Vector2(305,570),"time":Vector2(406,15)}
static func position_for(key:String,scale:float) -> Vector2:
	match key:
		"health":return Vector2(22,698-98*scale)
		"ammo":return Vector2(1258-263*scale,693-116*scale)
		"gear":return Vector2(640-345*scale,709-139*scale)
	return Vector2(640-234*scale,15)
static func attach(ui:Node):
	var groups={}
	for key in ORIGINS:
		var group=Control.new();group.name="Hud_"+key;group.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.hud.add_child(group);groups[key]=group
	for child in ui.hud.get_children():
		if not child is Control or child in groups.values():continue
		if child is HudSymbols:
			child.reparent(groups.gear,false);child.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);child.position=-ORIGINS.gear;continue
		if child==ui.reticle or child is KillFeed or child is MatchScoreboard or child==ui.flash_overlay:continue
		var pos:Vector2=child.position;var key=""
		if pos.y>=570:key="health" if pos.x<300 else "ammo" if pos.x>=990 else "gear"
		elif pos.y<80 and pos.x>=400 and pos.x<990:key="time"
		if not key.is_empty():child.reparent(groups[key],false);child.position=pos-ORIGINS[key]
	apply(ui)
static func apply(ui:Node):
	if not is_instance_valid(ui.hud):return
	var amount=clampf(float(ui.game.profile.get("hud_scale",.8)),.65,1.1)
	for key in ORIGINS:
		var group=ui.hud.get_node_or_null("Hud_"+key)
		if group:group.position=position_for(key,amount);group.scale=Vector2.ONE*amount
	for panel in ui.hud.find_children("*","Panel",true,false):
		if not panel.has_meta("hud_plate"):continue
		var style=panel.get_theme_stylebox("panel").duplicate();style.bg_color.a=clampf(float(ui.game.profile.get("hud_opacity",.38)),.1,.8);panel.add_theme_stylebox_override("panel",style)
