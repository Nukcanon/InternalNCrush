extends RefCounted
class_name PracticeSession
const TARGETS=[Vector3(-7,.15,17),Vector3(0,.15,7),Vector3(7,.15,-3),Vector3(-7,.15,-23),Vector3(-25,4.35,0),Vector3(25,8.55,0),Vector3(0,12.75,-18),Vector3(7,.15,17),Vector3(-10,.15,30)]
static func start(game):
	game.stop_room_search();game.options=Rules.default_options();game.options.merge({"practice":true,"map":31,"map_random":false,"map_rotation":false,"max_players":16,"bots":0,"infinite":true,"autoheal":true},true);game.server=true;game.local_id=1;game.phase="lobby";game.build_world();game.add_player(1,game.profile.nick,game.profile.token)
	for i in range(TARGETS.size()):
		var id=-i-1;game.add_player(id,"회복 연습" if i==8 else "이동 표적" if i in [1,3,5] else "방호 표적" if i==7 else "표적 %d"%(i+1),"training"+str(i))
		var p=game.players[id];p.team=0 if i==8 else 1;p.role=2 if i==7 else i%6;p.primary=Catalog.first(p.role);game.actors[id].set_team(p.team)
	game.players[1].team=0;game.phase="combat";game.remaining=999999.
	for id in game.players:game.spawn(id)
	game.ui.show_hud();game.announce("FIELD ACADEMY · 공격하지 않는 표적 · B 병과/장비 · 입구 보급 구역에서 탄약·스킬 재충전")
	game.ui.practice_hint_until=Time.get_ticks_msec()+8000
static func spawn_point(id:int) -> Vector3:return TARGETS[clampi(-id-1,0,TARGETS.size()-1)] if id<0 else Vector3(0,.15,35)
static func input(game,id:int):
	var p=game.players[id];var a=game.actors[id];var index=-id-1
	a.input_state.fire=false;a.input_state.alt=false;a.input_state.use=false;a.input_state.jump=false;a.input_state.sprint=false;a.input_state.crouch=false;a.input_state.ads=false;a.input_state.x=0.;a.input_state.z=0.;a.input_state.yaw=PI;a.input_state.pitch=0.
	if index in [1,3,5]:
		var desired=spawn_point(id).x+sin(game.clock*.55+index)*3.
		a.input_state.x=clampf((a.position.x-desired)*.8,-.40,.40)
	if index==7:p.shield=game.clock+1.
	if index==8 and p.hp>90. and fmod(game.clock,10.)<.04:p.hp=35.
static func tick(game):
	if not game.players.has(1):return
	var p=game.players[1];var a=game.actors[1]
	if p.alive and a.position.z>30. and absf(a.position.x)<12. and game.clock>float(p.get("refit_ready",0)):
		game.equip_ammo(p);p.skill_ready=0.;p.gadget_ready=0.;p.energy=180.;p.heal_mag=3;p.heal_reserve=3;GadgetLoadout.reset(p);p.hp=100.;p.refit_ready=game.clock+2.
		for device in game.devices.values():
			if device.kind=="turret" and int(device.owner)==1:device.upgrade_ready=0.
