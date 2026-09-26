extends Node3D
class_name GameAudio
var catalog={}
var profile={}
var streams={}
var spatial=[]
var local=[]
var serial=0
var feedback_voices=[]
var movement_voices=[]
var blast_voices=[]
signal played(key:String,world:bool)
const FEEDBACK=["hit","confirm","hurt","armor_hurt","hurt_female","armor_hurt_female","deploy"]
func stop_all():
	for voice in spatial+local+feedback_voices+movement_voices+blast_voices:
		if is_instance_valid(voice):voice.stop();voice.stream=null
func _exit_tree():stop_all()
func _ready():
	if AudioServer.get_bus_effect_count(0)==0:
		var limiter=AudioEffectLimiter.new();limiter.ceiling_db=-1.;limiter.threshold_db=-2.;AudioServer.add_bus_effect(0,limiter)
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"))
	for key in catalog:streams[key]=load(catalog[key].file)
	for i in range(56):
		var player=AudioStreamPlayer3D.new();player.max_distance=90;player.unit_size=6;player.attenuation_model=AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE;add_child(player);spatial.append(player)
	for i in range(16):var player=AudioStreamPlayer.new();add_child(player);local.append(player)
	for i in range(8):var player=AudioStreamPlayer.new();add_child(player);feedback_voices.append(player)
	for i in range(12):var player=AudioStreamPlayer3D.new();add_child(player);movement_voices.append(player)
	for i in range(8):var player=AudioStreamPlayer3D.new();add_child(player);blast_voices.append(player)
func play(key:String,where:Vector3,world:bool,gain=0.):
	if DisplayServer.get_name()=="headless":return
	if not streams.has(key):return
	var candidates=spatial if world else feedback_voices if key in FEEDBACK else local
	if world and key.begins_with("step_"):candidates=movement_voices
	elif world and key in ["explosion","bomb_explosion","flash","smoke"]:candidates=blast_voices
	var voice=candidates[serial%candidates.size()];serial+=1
	# Retrigger pain per received hit without stacking multiple full vocal phrases.
	if key in ["hurt","armor_hurt","hurt_female","armor_hurt_female"]:
		for candidate in feedback_voices:
			if candidate.get_meta("pain",false):candidate.stop()
	for candidate in candidates:
		if not candidate.playing:voice=candidate;break
	voice.stop();voice.stream=streams[key]
	voice.set_meta("pain",key in ["hurt","armor_hurt","hurt_female","armor_hurt_female"])
	var data=catalog[key];var category=category_gain(str(data.category))
	if category<=0:return
	voice.volume_db=linear_to_db(category)+float(data.gain_db)+gain
	voice.pitch_scale=1.+sin(serial*1.31)*(.025 if key.begins_with("gun_") else .065)
	if world:
		voice.position=where;voice.max_distance=40. if key.begins_with("step_") else 160.;voice.unit_size=7. if key.begins_with("step_") else 12.
		voice.attenuation_model=AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		if key in ["explosion","bomb_explosion"]:voice.unit_size=20.;voice.max_distance=220.
	if world and key=="bomb_beep":voice.max_distance=28.;voice.unit_size=7.;voice.pitch_scale=1.
	if key in ["bomb_planted","bomb_dropped","bomb_defused"]:voice.pitch_scale=1.
	if world and key=="bomb_defuse":voice.max_distance=16.;voice.unit_size=3.;voice.pitch_scale=1.
	voice.play();played.emit(key,world)

func category_gain(category:String) -> float:
	return clampf(float(profile.get(category,.75)),0,1) if category in ["ui_volume","hit_volume"] else 1.0
