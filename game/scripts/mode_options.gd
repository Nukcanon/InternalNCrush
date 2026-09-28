extends RefCounted
class_name ModeOptions
const NETWORK_KEYS=["minutes","target","team_respawns","capture_hold","capture_seconds","rounds","starting_cash","prep_seconds","round_minutes","bomb_seconds","buy_seconds","lives","next_teams","weapon_rule"]
const FIELDS=[
	["minutes","경기 시간 (분 · 0은 무제한)",[0,1,2,3],0,180,1],
	["target","목표 처치 수",[0,1],1,10000,1],
	["team_respawns","팀별 부활 횟수",[2],0,10000,1],
	["capture_seconds","거점 점령 시간 (초 · 1명 기준 / 짧을수록 빠름)",[3],1,60,1],
	["capture_hold","모든 거점 점령 유지 시간 (초)",[3],1,3600,1],
	["rounds","진행 라운드 수 (짝수)",[4],2,100,2],
	["starting_cash","시작 금액",[4],0,8000,100],
	["prep_seconds","준비 시간 (초)",[4],5,120,1],
	["round_minutes","라운드 시간 (분)",[4],1,60,1],
	["bomb_seconds","폭탄 설치 후 폭발 시간 (초)",[4],30,120,1],
	["buy_seconds","전투 시작 후 구매 시간 (초 · 0~300 / 준비 시간 별도)",[4],0,300,1],
	["lives","개인별 라운드 부활 횟수",[4],0,10,1]]
static func install(ui:Node):
	var parent=VBoxContainer.new();ui.stack.add_child(parent);ui.mode_fields=parent
	for field in FIELDS:
		var row=HBoxContainer.new();parent.add_child(row);row.set_meta("modes",field[2])
		var label=Label.new();label.text=field[1];label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
		var number=SpinBox.new();number.name=field[0];number.min_value=field[3];number.max_value=field[4];number.step=field[5];number.value=ui.game.options.get(field[0],Rules.default_options()[field[0]]);number.custom_minimum_size.x=135;row.add_child(number)
		var key=field[0];number.value_changed.connect(func(value):ui.game.options[key]=int(value);refresh(ui))
	refresh(ui)
static func refresh(ui:Node):
	if not is_instance_valid(ui.mode_fields):return
	for row in ui.mode_fields.get_children():
		row.visible=int(ui.game.options.mode) in row.get_meta("modes",[])
		var purchase=row.get_node_or_null("buy_seconds")
		if purchase:
			var cap=mini(300,int(ui.game.options.get("round_minutes",5))*60)
			ui.game.options.buy_seconds=clampi(int(ui.game.options.get("buy_seconds",60)),0,cap)
			purchase.set_value_no_signal(ui.game.options.buy_seconds);purchase.max_value=cap
static func network(options:Dictionary) -> Dictionary:
	var out={}
	for key in NETWORK_KEYS:out[key]=int(options.get(key,Rules.default_options()[key]))
	return out
static func seconds(options:Dictionary) -> float:
	var minutes=int(options.get("round_minutes",5)) if int(options.mode)==4 else int(options.get("minutes",10))
	return float(minutes)*60. if minutes>0 else 1e12
