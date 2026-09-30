class_name Prof
extends RefCounted
## Section timers for profiling runs (environment INC_PROFILE=1). Disabled
## builds pay one static bool test per call site.
static var enabled:bool=OS.has_environment("INC_PROFILE")
static var data={}
static func add(key:String,start:int):
	if enabled:data[key]=int(data.get(key,0))+Time.get_ticks_usec()-start
static func now() -> int:return Time.get_ticks_usec() if enabled else 0
