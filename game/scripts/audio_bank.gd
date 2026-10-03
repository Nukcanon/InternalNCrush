extends Node3D
class_name GameAudio
var catalog={}
var profile={}
var streams={}
var vocal_streams={}
var spatial=[]
var local=[]
var serial=0
var feedback_voices=[]
var movement_voices=[]
var blast_voices=[]
var announcer:AudioStreamPlayer
var announcement_queue=[]
signal played(key:String,world:bool)
const FEEDBACK=["hit","confirm","hurt","armor_hurt","hurt_female","armor_hurt_female","deploy","knife_wall","wrench_wall","knife_flesh","wrench_flesh","wrench_repair"]
func stop_all():
	announcement_queue.clear()
	if is_instance_valid(announcer):announcer.stop();announcer.stream=null
	for voice in spatial+local+feedback_voices+movement_voices+blast_voices:
		if is_instance_valid(voice):voice.stop();voice.stream=null
func _exit_tree():stop_all()
func _ready():
	if AudioServer.get_bus_effect_count(0)==0:
		var limiter=AudioEffectLimiter.new();limiter.ceiling_db=-1.;limiter.threshold_db=-2.;AudioServer.add_bus_effect(0,limiter)
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"))
	var loaded_files={}
	for key in catalog:
		var file=str(catalog[key].file)
		if not loaded_files.has(file):loaded_files[file]=load(file)
		streams[key]=loaded_files[file]
	for family in VocalGunfire.FAMILIES:
		if ResourceLoader.exists(VocalGunfire.path(family)):vocal_streams[family]=load(VocalGunfire.path(family))
	announcer=AudioStreamPlayer.new();add_child(announcer);announcer.finished.connect(_next_announcement)
	for i in range(56):
		var player=AudioStreamPlayer3D.new();player.max_distance=90;player.unit_size=6;player.attenuation_model=AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE;add_child(player);spatial.append(player)
	for i in range(16):var player=AudioStreamPlayer.new();add_child(player);local.append(player)
	for i in range(8):var player=AudioStreamPlayer.new();add_child(player);feedback_voices.append(player)
	for i in range(12):var player=AudioStreamPlayer3D.new();add_child(player);movement_voices.append(player)
	for i in range(8):var player=AudioStreamPlayer3D.new();add_child(player);blast_voices.append(player)
## 1.5.1: a clip with recorded alternatives ("variants": n in the manifest, files key_v1..)
## plays one of them at random (the hurt voices).
func variant_stream(key:String) -> AudioStream:
	var n=int(catalog[key].get("variants",1))
	if n>1:
		var k=randi()%n
		if k>0 and streams.has(key+"_v%d"%k):return streams[key+"_v%d"%k]
	return streams[key]
func play(key:String,where:Vector3,world:bool,gain=0.):
	if DisplayServer.get_name()=="headless":return
	if not streams.has(key):return
	if str(catalog[key].category)=="announcer":
		if key.begins_with("win_"):announcement_queue.clear()
		if announcement_queue.size()>=8:announcement_queue.pop_front()
		announcement_queue.append(key)
		if not announcer.playing:_next_announcement()
		return
	if world:
		var listener=get_viewport().get_camera_3d()
		if is_instance_valid(listener) and listener.global_position.distance_to(where)>audible_range(key):return
	var candidates=spatial if world else feedback_voices if key in FEEDBACK else local
	if world and key.begins_with("step_"):candidates=movement_voices
	elif world and key in ["explosion","rocket_explosion","bomb_explosion","flash","smoke"]:candidates=blast_voices
	var voice=candidates[serial%candidates.size()];serial+=1
	# Retrigger pain per received hit without stacking multiple full vocal phrases.
	if key in ["hurt","armor_hurt","hurt_female","armor_hurt_female"]:
		for candidate in feedback_voices:
			if candidate.get_meta("pain",false):candidate.stop()
	for candidate in candidates:
		if not candidate.playing:voice=candidate;break
	var vocal=VocalGunfire.family(key,catalog) if profile.get("gunfire_reduction",false) else ""
	var use_vocal=vocal_streams.has(vocal)
	if use_vocal:
		# Long syllables must not stack on every machine-gun/beam tick.
		# Allow two overlapping attacks per nearby emitter, then recycle the oldest.
		var matching=[]
		for candidate in candidates:
			if candidate.playing and candidate.get_meta("vocal_family","")==vocal and (not world or candidate.position.distance_squared_to(where)<4.):matching.append(candidate)
		if matching.size()>=2:
			matching.sort_custom(func(a,b):return int(a.get_meta("vocal_serial",0))<int(b.get_meta("vocal_serial",0)))
			voice=matching[0]
	voice.stop();voice.stream=vocal_streams[vocal] if use_vocal else variant_stream(key)
	voice.set_meta("vocal_family",vocal if use_vocal else "");voice.set_meta("vocal_serial",serial)
	voice.set_meta("pain",key in ["hurt","armor_hurt","hurt_female","armor_hurt_female"])
	voice.set_meta("cue",key)
	var data=catalog[key];var category=category_gain(str(data.category))
	if category<=0:return
	voice.volume_db=linear_to_db(category)+float(data.gain_db)+gain
	if use_vocal:voice.volume_db=linear_to_db(category)-9.+minf(gain,0.)
	voice.pitch_scale=1.+sin(serial*1.31)*(.025 if key.begins_with("gun_") else .065)
	if use_vocal:voice.pitch_scale=1.
	if world:
		voice.position=where;voice.max_distance=audible_range(key);voice.unit_size=7. if audible_range(key)<=40. else 12.
		voice.attenuation_model=AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		if key in ["explosion","rocket_explosion","bomb_explosion","flash","smoke"]:voice.unit_size=20.
	if world and key=="bomb_beep":voice.unit_size=16.;voice.pitch_scale=1.
	if key in ["bomb_planted","bomb_dropped","bomb_defused","win_blue","win_orange"]:voice.pitch_scale=1.
	if world and key=="bomb_defuse":voice.max_distance=16.;voice.unit_size=3.;voice.pitch_scale=1.
	if world and key=="bipod":voice.unit_size=2. # (fades out over its 10 m)
	voice.play();played.emit(key,world)

func category_gain(category:String) -> float:
	return clampf(float(profile.get(category,.75)),0,1) if category in ["ui_volume","hit_volume"] else 1.0
func _next_announcement():
	if announcement_queue.is_empty():return
	var key=announcement_queue.pop_front()
	announcer.stream=streams[key];announcer.pitch_scale=1.;announcer.volume_db=float(catalog[key].gain_db)
	announcer.play();played.emit(key,false)
static func audible_range(key:String) -> float:
	if key in ["explosion","rocket_explosion","bomb_explosion","flash","smoke"]:return 220.
	if key=="bomb_beep":return 90.
	if key in ["link_loop","shield_loop"]:return 20. # (1.5.2, the user: the LINK and shield hums carry 20 m)
	if key=="bipod":return 10. # (1.5.4, the user: heard within 10 m only)
	if key.begins_with("gun_") or key in ["rocket_launch","skill","skill_end","turret_detect"]:return 160.
	return 40.
var loop_streams={}
## A looping copy of a clip marked "loop" in the manifest (LINK / FIX hum).
func loop_stream(key:String) -> AudioStream:
	if loop_streams.has(key):return loop_streams[key]
	if not streams.has(key) or not streams[key] is AudioStreamWAV:return null
	var wav:AudioStreamWAV=streams[key].duplicate()
	wav.loop_mode=AudioStreamWAV.LOOP_FORWARD;wav.loop_begin=0;wav.loop_end=int(round(wav.get_length()*wav.mix_rate))
	loop_streams[key]=wav;return wav
func stop_key(key:String):
	for voice in spatial+local+feedback_voices+movement_voices+blast_voices:
		if is_instance_valid(voice) and voice.get_meta("cue","")==key:voice.stop()
