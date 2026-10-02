extends RefCounted
class_name Rules
const VERSION = "1.4.10"
const MAPS = ["항구", "조선소", "제철소", "연구소", "사막 기지", "운하", "중앙역", "구시가지", "정비 공장", "산동네", "과수원", "발전소", "분수 광장", "물류 창고", "실험 단지", "폐공장", "고층 빌딩", "재래시장", "채석장", "요새", "원전", "수로교", "도서관", "폐선장", "수도원", "용광로", "온실", "지하 금고", "해안 기지", "서버 센터", "산성", "훈련장"]
const MAP_PLAYERS = [32,32,16,16,16,32,16,6,6,6,6,6,6,8,8,8,8,8,8,8,8,8,8,8,8,12,12,12,12,12,12,16]
static func maps_for_size(count:int,mode:int=-1) -> Array:
	var out=[]
	for i in range(MAPS.size()):
		if i!=31 and MAP_PLAYERS[i]==count and (mode<0 or ((i>=19)==(mode==4))):out.append(i)
	return out
static func step_length(sprint:bool,crouch:bool) -> float:return 2.1 if sprint else 1.0 if crouch else 1.55

const WALK_SPEED = 3.2
const RUN_SPEED = 6.2
const CROUCH_SPEED = 1.55
const SLIDE_TAP_MS = 550
const SLIDE_DURATION = .95
const SLIDE_SPEED = 8.6
const SLIDE_DECAY = 4.4
const REGEN_DELAY = 10.0
const REGEN_RATE = 1.0
const SPAWN_PROTECTION = 1.5
# 1.4.3: a respawned player may fire back after one second (still protected).
const SPAWN_ATTACK_DELAY = 1.0
static func attack_blocked_until(p:Dictionary) -> float:return float(p.get("protect",0))-(SPAWN_PROTECTION-SPAWN_ATTACK_DELAY)
static var PORT:int = clampi(int(OS.get_environment("INC_TEST_PORT")),1024,65533) if OS.has_environment("INC_TEST_PORT") else 27888
static var DISCOVERY:int = PORT+1
const CLASS_HP=[100.,100.,150.,100.,130.,100.]
static func max_hp(p:Dictionary) -> float:return CLASS_HP[clampi(int(p.get("role",0)),0,5)]
const CLASSES = ["돌격", "정찰", "중화기", "공병", "통제", "메딕"]
const MODES = ["팀 데스매치", "개인전", "제한 부활 팀전", "거점 점령", "설치 / 해체"]
const GADGETS = ["보호판", "표식기", "거치대", "엄폐물", "연막탄", "응급 키트"]
const SKILLS = ["기동", "하드비트센서", "방호", "포탑", "둔화 구역", "무적 보호"]
const GADGET_HELP = ["보호판: 3개 지급 · 한 장당 내구도 25 · 방어구보다 먼저 소모 · 한 번에 한 장만 사용", "표식기: 장착 시 자동 · 스코프 영역 안 가까운 적 1.5초 고정 추적 → 팀 전체 6초 투시 · 대상에게 경고", "거치대: 장착하면 앉아서 사격 시 자동으로 퍼짐 65% · 반동 60% 감소", "엄폐물: 조준 방향에 설치, 내구도별 선택", "연막 3 / 섬광 3 / 파편 2 중 하나 선택 · 3번 선택 후 클릭 또는 G 사용", "응급 키트: 가까운 아군 또는 자신을 25 회복"]
const SKILL_HELP = ["기동: 5초 고속이동 3초 빠른이동 · 재사용 24초", "하드비트센서: 맵 크기에 따라 35~60m · 4초 표시 · 재사용 40초", "방호: 이동하며 6초 동안 전방 피해 85% 감소", "포탑: F 위치 선택, 클릭 설치 · F키로 업그레이드 · 전방 100도 · 자동 사격 · 사거리 55~100m(맵 크기) · 강화마다 +10% · 재사용 20초", "둔화 구역: 반경 15m / 8초 / 이동 속도 65% 감소 · 벽 너머 제외", "무적 보호: F 후 아군 클릭: 자신과 아군 / 빈 곳 클릭: 자신 · 6초 무적 · 재사용 45초"]
const SECONDARIES = ["pistol", "heavy_pistol", "auto_pistol", "eng_pistol", "burst_pistol", "med_pistol"]
static func medic_cap(count:int) -> int:
	return 0 if count <= 0 else 1 + maxi(0, count - 4) / 3
static func loss_reward(stage:int) -> int:
	return [1900,3000,3300][clampi(stage - 1,0,2)]
static func damage_water(hit_submerged:bool, shooter_wading:bool, target_outside:bool) -> float:
	return 0.5 if hit_submerged or (shooter_wading and target_outside) else 1.0
static func ammo_pickup(capacity:int) -> int:
	return maxi(1, int(ceil(capacity * 0.25)))
static func score_parts(p:Dictionary) -> Dictionary:
	return {"kills":int(p.get("kills",0))*100,"assists":int(p.get("assists",0))*75,"healing":roundi(float(p.get("healed",0))*.6),"builds":int(p.get("builds",0))*80,"objectives":int(p.get("objective",0))*50,"deaths":-int(p.get("deaths",0))*25}
static func score(p:Dictionary) -> int:
	var total=0
	for value in score_parts(p).values():total+=int(value)
	return total
static func rating(p:Dictionary) -> float:
	return float(score(p)) / maxf(1.0,p.get("played",60.0)/60.0)
static func default_options() -> Dictionary:
	return {"room":"Internal N Crush", "mode":0,"map":13,"max_players":8,"skills":true,"classes":true,"weapon_rule":0,"infinite":false,"join":2,"teams":0,"next_teams":2,"lives":0,"shared_lives":true,"minutes":10,"target":60,"bots":0,"bot_difficulty":2,"friendly":false,"autoheal":false,"password":"","rounds":4,"map_random":true,"map_rotation":true,"map_size":8,"prep_seconds":30,"team_respawns":60,"capture_hold":60,"capture_seconds":5,"starting_cash":800,"round_minutes":5,"bomb_seconds":45,"buy_seconds":60}
static func balanced_ids(ps:Dictionary) -> Dictionary:
	var ids=ps.keys()
	ids.sort_custom(func(a,b):return rating(ps[a])>rating(ps[b]))
	var teams={0:[],1:[]};var sums=[0.0,0.0]
	for id in ids:
		var t=0 if teams[0].size()<teams[1].size() else 1 if teams[1].size()<teams[0].size() else (0 if sums[0]<=sums[1] else 1)
		teams[t].append(id);sums[t]+=rating(ps[id])
	return teams

static func sanitize_room(options:Dictionary):
	options.weapon_rule=WeaponRules.mode(options)
	if options.weapon_rule>0:options.skills=false;options.classes=true
	options.mode=clampi(int(options.get("mode",0)),0,4)
	options.map=clampi(int(options.get("map",13)),0,MAPS.size()-1)
	options.max_players=clampi(int(options.get("max_players",8))/2*2,2,12 if int(options.mode)==4 else 32)
	if options.map!=31 and ((int(options.map)>=19)!=(int(options.mode)==4)):
		options.map=19 if int(options.mode)==4 else 13
	if options.max_players>MAP_PLAYERS[options.map]:
		var choices=[]
		for i in range(31):
			if MAP_PLAYERS[i]>=options.max_players and ((i>=19)==(int(options.mode)==4)):choices.append(i)
		if not choices.is_empty():options.map=choices[0]
	options.map_size=MAP_PLAYERS[options.map]
	options.bots=clampi(int(options.get("bots",0)),0,int(options.max_players)-1)
	options.rounds=clampi(int(options.get("rounds",4)),2,100)
	options.rounds+=options.rounds%2
	options.prep_seconds=clampi(int(options.get("prep_seconds",30)),5,120)
	options.minutes=clampi(int(options.get("minutes",10)),0,180)
	options.target=clampi(int(options.get("target",60)),1,10000)
	options.team_respawns=clampi(int(options.get("team_respawns",60)),0,10000)
	options.capture_hold=clampi(int(options.get("capture_hold",60)),1,3600)
	options.capture_seconds=clampi(int(options.get("capture_seconds",5)),1,60)
	options.starting_cash=clampi(int(options.get("starting_cash",800)),0,8000)
	options.round_minutes=clampi(int(options.get("round_minutes",5)),1,60)
	options.bomb_seconds=clampi(int(options.get("bomb_seconds",45)),30,120)
	options.buy_seconds=clampi(int(options.get("buy_seconds",60)),0,mini(300,int(options.round_minutes)*60))
	options.lives=clampi(int(options.get("lives",0)),0,10)
static func random_map(options:Dictionary,avoid:int=-1) -> int:
	var choices=maps_for_size(int(options.get("map_size",8)),int(options.mode))
	if choices.size()>1:choices.erase(avoid)
	return choices.pick_random() if not choices.is_empty() else int(options.map)

