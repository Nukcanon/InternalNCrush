class_name WeaponRules
extends RefCounted
const PISTOLS=["pistol","heavy_pistol","auto_pistol","dual_pistols"]
static func mode(options:Dictionary) -> int:return clampi(int(options.get("weapon_rule",0)),0,2)
static func allows_slot(options:Dictionary,slot:int) -> bool:
	var rule=mode(options)
	return rule==0 or slot==2 or (rule==1 and slot==MeleeCombat.SLOT) or (rule==2 and slot==1)
static func enforce(options:Dictionary,p:Dictionary):
	var rule=mode(options);p.knife_only=rule==1
	if rule==0:return
	p.primary="";p.owned_primary=false
	if p.secondary not in PISTOLS:p.secondary="pistol"
	if not allows_slot(options,int(p.slot)):p.slot=MeleeCombat.SLOT if rule==1 else 1
static func selection(options:Dictionary,data:Dictionary) -> Dictionary:
	if mode(options)==0:return data
	var result=data.duplicate();result.primary=""
	if mode(options)==1 or result.get("secondary","pistol") not in PISTOLS:result.secondary="pistol";result.repair=false
	return result
static func build(ui:Node):
	ui.option("사용 무기",["모든 무기","칼만 · 가젯 허용 / 스킬 금지","권총만 · 가젯 허용 / 스킬 금지"],mode(ui.game.options),func(i):
		ui.game.options.weapon_rule=i
		if i>0:ui.game.options.skills=false;ui.game.options.classes=true)
