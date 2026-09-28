extends SceneTree
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	expect(DisplayServer.get_name()!="headless","audio test requires rendered Dummy-audio run")
	expect(VocalGunfire.ready(),"all seven approved clips imported")
	var bank=GameAudio.new();root.add_child(bank);bank.profile={"gunfire_reduction":false}
	bank.play("gun_a1",Vector3.ZERO,false)
	expect(bank.local.any(func(voice):return voice.stream==bank.streams.gun_a1),"default uses normal recorded gun")
	bank.stop_all();bank.profile.gunfire_reduction=true
	for shot in range(30):bank.play("gun_a1",Vector3.ZERO,false)
	var voices=bank.local.filter(func(voice):return voice.playing and voice.get_meta("vocal_family","")=="rifle")
	expect(voices.size()<=2 and voices.size()>0,"automatic fire has bounded vocal overlap")
	expect(voices.all(func(voice):return voice.stream==bank.vocal_streams.rifle and voice.pitch_scale==1.),"approved voice and pitch retained")
	bank.play("ui",Vector3.ZERO,false)
	expect(bank.local.any(func(voice):return voice.stream==bank.streams.ui),"menu click unaffected")
	bank.play("heal",Vector3.ZERO,false)
	expect(bank.local.any(func(voice):return voice.stream==bank.streams.heal),"non-gun healing skill unaffected")
	bank.play("link_fire",Vector3.ZERO,false)
	expect(bank.local.any(func(voice):return voice.stream==bank.vocal_streams.energy),"LINK gun uses vocal alternative")
	bank.stop_all();expect(bank.local.all(func(voice):return not voice.playing and voice.stream==null),"leaving match releases vocal playback")
	bank.free();await process_frame;print("VOCAL_AUDIO_RESULT failures=",failures);quit(1 if failures else 0)
