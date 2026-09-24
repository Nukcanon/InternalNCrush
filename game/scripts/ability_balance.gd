extends RefCounted
class_name AbilityBalance
const COOLDOWNS=[24.,40.,30.,35.,30.,45.]
const DURATIONS=[5.,4.,6.,180.,8.,4.]
const COVER_HP=[180,300,420]
const SCAN_RANGE=35.
const SLOW_RADIUS=11.
const SMOKE_DURATION=10.
const FLASH_RANGE=13.
const FLASH_MAX=2.2
static func turret_hp(level:int) -> float:return 180.+40.*(clampi(level,1,4)-1)
static func turret_dps(level:int) -> float:return TurretLogic.DAMAGE[clampi(level,1,4)-1]/TurretLogic.INTERVALS[clampi(level,1,4)-1]
static func turret_range(level:int) -> float:return 55.+2.*(clampi(level,1,4)-1)
static func flash_duration(distance:float,facing:float) -> float:
	return FLASH_MAX*clampf(1.-distance/FLASH_RANGE,0.,1.)*lerpf(.20,1.,clampf((facing+.25)/1.25,0.,1.))
