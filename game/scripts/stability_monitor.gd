extends Node
class_name StabilityMonitor
# Local numeric diagnostics only. Two bounded files retain pre-crash context.
const MAX_BYTES=2*1024*1024
var game:Node
var elapsed=0.
var frames=0
var slow_frames=0
var longest_usec=0
var previous_usec=0
var file:FileAccess
func _ready():
	if OS.has_feature("web") or DisplayServer.get_name()=="headless" or "--no-save-profile" in OS.get_cmdline_user_args():set_process(false);return
	open_log();previous_usec=Time.get_ticks_usec()
	write_sample("start")
func open_log():
	if file:file.close()
	var path="user://stability.jsonl"
	var current=FileAccess.open(path,FileAccess.READ) if FileAccess.file_exists(path) else null
	var bytes=current.get_length() if current else 0
	if current:current.close()
	if bytes>=MAX_BYTES:
		DirAccess.remove_absolute("user://stability.previous.jsonl")
		DirAccess.rename_absolute(path,"user://stability.previous.jsonl")
	file=FileAccess.open(path,FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file:file.seek_end()
func _process(dt:float):
	var stamp=Time.get_ticks_usec();var duration=stamp-previous_usec;previous_usec=stamp
	frames+=1;longest_usec=maxi(longest_usec,duration)
	if duration>50000:slow_frames+=1
	elapsed+=dt
	if elapsed>=10.:
		write_sample("sample");elapsed=0.;frames=0;slow_frames=0;longest_usec=0
func write_sample(event:String):
	if not file:return
	if file.get_position()>=MAX_BYTES:open_log()
	if not file:return
	var state={"event":event,"version":Rules.VERSION,"uptime_ms":Time.get_ticks_msec(),"phase":str(game.phase),"map":int(game.options.map),"players":game.players.size(),"frames":frames,"over_50ms":slow_frames,"max_frame_ms":longest_usec/1000.,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.,"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}
	file.store_line(JSON.stringify(state));file.flush()
func _exit_tree():
	if file:file.close()
