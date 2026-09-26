extends RefCounted
class_name AbilityBalance
const COOLDOWNS=[24.,40.,30.,30.,30.,45.]
const DURATIONS=[5.,4.,6.,180.,8.,6.]
const COVER_HP=[180,300,420]
const SCAN_RANGE=35.
const SCAN_MAX_RANGE=60.
static func scan_range(bounds:Vector2) -> float:return clampf(bounds.length()*.5,SCAN_RANGE,SCAN_MAX_RANGE)
const SLOW_RADIUS=15.
const SMOKE_DURATION=10.
const FLASH_RANGE=18.
const FLASH_MAX=4.5
static func skill_state(game:Node,id:int) -> Dictionary:
	var p=game.players.get(id,{})
	if p.is_empty():return {"remaining":0.,"duration":1.,"enabled":false,"label":"스킬"}
	var role=int(p.role);var remaining=maxf(0.,float(p.skill_ready)-game.clock)
	var duration=COOLDOWNS[role];var label=Rules.SKILLS[role]
	var enabled=game.options.skills and game.options.classes and game.phase=="combat" and game.can_attack(p)
	if role==3:
		# Installation and every upgrade share one 30-second ability clock.
		# Distance changes the action label, never the progress denominator/deadline.
		for device in game.devices.values():
			if device.kind=="turret" and int(device.owner)==id:
				remaining=maxf(remaining,float(device.get("upgrade_ready",0))-game.clock)
		var did=Deployment.nearby_turret(game,id)
		if did:
			var d=game.devices[did];label="포탑 강화"
			if d.level>=4:enabled=false;label="최대 단계"
		elif p.get("placing","")=="turret":label="설치 위치 선택"
	return {"remaining":remaining,"duration":duration,"enabled":enabled,"label":label}
static func turret_hp(level:int) -> float:return 180.+40.*(clampi(level,1,4)-1)
static func turret_dps(level:int) -> float:return TurretLogic.DAMAGE[clampi(level,1,4)-1]/TurretLogic.INTERVALS[clampi(level,1,4)-1]
static func turret_range(level:int) -> float:return 55.+2.*(clampi(level,1,4)-1)
static func flash_duration(distance:float,facing:float) -> float:
	return FLASH_MAX*clampf(1.-distance/FLASH_RANGE,0.,1.)*lerpf(.60,1.,clampf((facing+.25)/1.25,0.,1.))
