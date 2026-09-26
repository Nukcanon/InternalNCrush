extends RefCounted
class_name Rules
const VERSION = "1.2.2"
const MAPS = ["TIDAL YARD · 항구", "DRY DOCK · 물류 기지", "FOUNDRY · 주조 공장", "RESEARCH · 연구동", "MESA RELAY · 사막 관측소", "CANAL DISTRICT · 운하 지구", "TRANSIT HALL · 환승 터미널", "COURTYARD · 안뜰", "WORKSHOP · 정비소", "SWITCHBACK · 굽은 골목", "ORCHARD · 과수원", "POWER ROOM · 전력실", "FOUNTAIN · 분수 광장", "CARGO ROW · 적재 구역", "TWIN LAB · 쌍둥이 실험실", "FOUNDRY EAST · 동부 공장", "ROOFTOP · 옥상", "MARKET LOOP · 순환 시장", "QUARRY PASS · 채석 통로", "KASBAH · 성채 시장", "REACTOR · 이중 원자로", "VIADUCT · 고가 수로", "ARCHIVE · 기록 보관소", "SHIPBREAK · 해체 부두", "MONASTERY · 언덕 수도원", "FOUNDRY CORE · 용광로", "GREENHOUSE · 유리 온실", "METRO VAULT · 지하 금고", "COASTGUARD · 해안 통제소", "DATACENTER · 데이터 센터", "CITADEL · 산성", "FIELD ACADEMY · 훈련 기지"]
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
const REGEN_DELAY = 10.0
const REGEN_RATE = 1.0
const SPAWN_PROTECTION = 1.5
static var PORT:int = clampi(int(OS.get_environment("INC_TEST_PORT")),1024,65533) if OS.has_environment("INC_TEST_PORT") else 27888
static var DISCOVERY:int = PORT+1
const CLASS_HP=[100.,100.,150.,100.,130.,100.]
static func max_hp(p:Dictionary) -> float:return CLASS_HP[clampi(int(p.get("role",0)),0,5)]
const CLASSES = ["돌격", "정찰", "중화기", "공병", "통제", "메딕"]
const MODES = ["팀 데스매치", "개인전", "제한 부활 팀전", "거점 점령", "설치 / 해체"]
const GADGETS = ["보호판", "표식기", "거치대", "엄폐물", "연막탄", "응급 키트"]
const SKILLS = ["기동", "하드비트센서", "방호", "포탑", "둔화 구역", "무적 보호"]
const GADGET_HELP = ["보호판: 방어구 25 회복 · 최대 50", "표식기: 장착 시 자동 · 스코프 중앙에 가까운 적 2초 추적 → 팀 전체 6초 투시 · 대상에게 경고", "거치대: 장착하면 앉아서 사격 시 자동으로 퍼짐 65% · 반동 60% 감소", "엄폐물: 조준 방향에 설치, 내구도별 선택", "연막 3 / 섬광 3 / 파편 2 중 하나 선택 · 3번 선택 후 클릭 또는 G 사용", "응급 키트: 가까운 아군 또는 자신을 25 회복"]
const SKILL_HELP = ["기동: 5초 고속이동 3초 빠른이동 · 재사용 24초", "하드비트센서: 맵 크기에 따라 35~60m · 4초 표시 · 재사용 40초", "방호: 이동하며 6초 동안 전방 피해 85% 감소", "포탑: F 위치 선택, 클릭 설치 · F키로 업그레이드 · 전방 100도 · 자동 사격", "둔화 구역: 반경 15m / 8초 / 이동 속도 65% 감소 · 벽 너머 제외", "무적 보호: F 후 아군 클릭: 자신과 아군 / 빈 곳 클릭: 자신 · 6초 무적 · 재사용 45초"]
const SECONDARIES = ["pistol", "heavy_pistol", "auto_pistol", "eng_pistol", "burst_pistol", "med_pistol"]
static func medic_cap(count:int) -> int:
	return 0 if count <= 0 else 1 + maxi(0, count - 4) / 3
static func loss_reward(stage:int) -> int:
	return [1900,3000,3300][clampi(stage - 1,0,2)]
static func damage_water(hit_submerged:bool, shooter_wading:bool, target_outside:bool) -> float:
	return 0.5 if hit_submerged or (shooter_wading and target_outside) else 1.0
static func ammo_pickup(capacity:int) -> int:
	return maxi(1, int(ceil(capacity * 0.25)))
static func score(p:Dictionary) -> int:
	return int(p.get("kills",0)*100 + p.get("assists",0)*50 + p.get("objective",0)*35 + p.get("healed",0)*.3 + p.get("builds",0)*20 - p.get("deaths",0)*25)
static func rating(p:Dictionary) -> float:
	return float(score(p)) / maxf(1.0,p.get("played",60.0)/60.0)
static func default_options() -> Dictionary:
	return {"room":"Internal N Crush", "mode":0,"map":13,"max_players":8,"skills":true,"classes":true,"infinite":false,"join":2,"teams":0,"next_teams":0,"lives":3,"shared_lives":false,"minutes":10,"target":60,"bots":0,"bot_difficulty":1,"friendly":false,"autoheal":false,"password":"","rounds":0,"map_random":true,"map_rotation":false,"map_size":8,"prep_seconds":45}
static func balanced_ids(ps:Dictionary) -> Dictionary:
	var ids=ps.keys()
	ids.sort_custom(func(a,b):return rating(ps[a])>rating(ps[b]))
	var teams={0:[],1:[]};var sums=[0.0,0.0]
	for id in ids:
		var t=0 if teams[0].size()<teams[1].size() else 1 if teams[1].size()<teams[0].size() else (0 if sums[0]<=sums[1] else 1)
		teams[t].append(id);sums[t]+=rating(ps[id])
	return teams

static func sanitize_room(options:Dictionary):
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
	options.rounds=maxi(0,int(options.get("rounds",0)))
	options.prep_seconds=clampi(int(options.get("prep_seconds",45)),30,60)
static func random_map(options:Dictionary,avoid:int=-1) -> int:
	var choices=maps_for_size(int(options.get("map_size",8)),int(options.mode))
	if choices.size()>1:choices.erase(avoid)
	return choices.pick_random() if not choices.is_empty() else int(options.map)

