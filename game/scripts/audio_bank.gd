extends Node3D
class_name GameAudio
var catalog={}
var profile={}
var streams={}
var spatial=[]
var local=[]
var serial=0
func stop_all():
	for voice in spatial+local:
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
func play(key:String,where:Vector3,world:bool,gain=0.):
	if DisplayServer.get_name()=="headless":return
	if not streams.has(key):return
	var candidates=spatial if world else local;var voice=candidates[serial%candidates.size()];serial+=1
	for candidate in candidates:
		if not candidate.playing:voice=candidate;break
	voice.stop();voice.stream=streams[key]
	var data=catalog[key];var category=category_gain(str(data.category))
	if category<=0:return
	voice.volume_db=linear_to_db(category)+float(data.gain_db)+gain
	voice.pitch_scale=1.+sin(serial*1.31)*(.025 if key.begins_with("gun_") else .065)
	if world:
		voice.position=where;voice.max_distance=48. if key.begins_with("step_") else 160.;voice.unit_size=5. if key.begins_with("step_") else 12.
	voice.play()

func category_gain(category:String) -> float:
	return clampf(float(profile.get(category,.75)),0,1) if category in ["ui_volume","hit_volume"] else 1.0
