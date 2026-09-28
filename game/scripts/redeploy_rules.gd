class_name RedeployRules
extends RefCounted
const COOLDOWN=15.
static func available(g:Node,p:Dictionary) -> bool:
	if g.phase!="combat" or not p.get("alive",false):return false
	if g.options.get("practice",false):return true
	match int(g.options.mode):
		2:return int(g.tickets[int(p.team)])>0
		4:return int(p.get("lives",0))>0
	return int(g.options.mode) in [0,1,3]
static func wait_seconds(g:Node,p:Dictionary) -> float:
	return 0. if g.options.get("practice",false) else maxf(0.,float(p.get("redeploy_ready",0.))-g.clock)
static func warning(mode:int) -> String:
	var penalty={0:"상대 팀 점수가 1점 올라갑니다.",1:"현재 생명을 포기하고 시작 위치로 돌아갑니다.",2:"팀 부활 횟수가 1회 차감됩니다.",3:"점령 중인 위치를 떠나 본진으로 돌아갑니다.",4:"이번 경기 전체의 개인 부활 횟수가 1회 차감되고 구매한 장비를 잃습니다. 구매 시간 안에 팀 시작 위치에서 다시 구매해야 합니다."}.get(mode,"")
	return penalty+"\n사망 처리 후 선택한 장비를 적용합니다. 15초마다 한 번 사용할 수 있습니다.\n계속하시겠습니까?"
