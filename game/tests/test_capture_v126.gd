extends SceneTree
class Fixture extends Node:
	var options={"capture_seconds":5}
	var zone_capture=[0.,0.,0.]
	var zone_owner=[-1,-1,-1]
	var zone_counts=[[0,0],[0,0],[0,0]]
	var players={}
	var actors={}
	var arena={"zones":[Vector3.ZERO,Vector3(30,0,0),Vector3(60,0,0)]}
	var notices=[]
	@rpc("authority","call_local","reliable",0)
	func zone_announcement(index:int,team:int):notices.append([index,team])
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	print("PASS " if ok else "FAIL ",message)
	if not ok:failures+=1
func run():
	var g=Fixture.new();root.add_child(g)
	expect(not ControlCapture.in_zone(Vector3(0,4.2,0),Vector3.ZERO) and ControlCapture.in_zone(Vector3(0,.8,0),Vector3.ZERO),"upstairs actors cannot capture through a ceiling; normal jumping stays in zone")
	for i in range(1,6):
		g.players[i]={"alive":true,"team":0,"objective":0};var a=Node3D.new();g.add_child(a);a.position=Vector3(100,0,0);g.actors[i]=a
	g.actors[1].position=Vector3.ZERO;ControlCapture.tick(g,1.)
	expect(g.zone_capture[0]==1.,"single participant preserves five-second neutral capture")
	g.actors[2].position=Vector3.ZERO;g.actors[3].position=Vector3.ZERO;ControlCapture.tick(g,1.)
	expect(g.zone_capture[0]==3.,"three participants capture twice as fast")
	g.players[4].team=1;g.actors[4].position=Vector3.ZERO;ControlCapture.tick(g,1.)
	expect(g.zone_capture[0]==3. and ControlCapture.state(g,0).contested,"enemy presence freezes progress and reports contention")
	g.players[4].alive=false;ControlCapture.tick(g,1.)
	expect(g.zone_owner[0]==0 and g.notices==[[0,0]],"dead opponents do not contest; capture announces once")
	expect(g.players[1].objective==2 and g.players[2].objective==2 and g.players[3].objective==2 and g.players[4].objective==0,"only living capturing participants receive credit")
	ControlCapture.tick(g,5.);expect(g.notices.size()==1,"owned point does not repeat announcement")
	for id in [1,2,3]:g.actors[id].position=Vector3(100,0,0)
	g.players[4].alive=true;ControlCapture.tick(g,5.)
	expect(g.zone_owner[0]==0 and is_equal_approx(ControlCapture.state(g,0).progress,.5),"enemy takeover fills from bottom across the previous team color")
	ControlCapture.tick(g,5.);expect(g.zone_owner[0]==1 and g.notices==[[0,0],[0,1]],"completed takeover announces the new team")
	expect(ControlCapture.speed(4)==2.5 and ControlCapture.speed(16)==2.5,"large groups are capped at 2.5 times speed")
	g.actors[1].position=Vector3(30,0,0);g.actors[2].position=Vector3(60,0,0);ControlCapture.tick(g,5.)
	expect(g.notices.has([1,0]) and g.notices.has([2,0]),"both remaining points independently announce capture")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"))
	for team in ["blue","orange"]:
		for letter in ["a","b","c"]:
			var cue="capture_"+team+"_"+letter
			expect(manifest.has(cue) and ResourceLoader.exists(manifest[cue].file),"packaged announcement "+cue)
	for cue in ["win_blue","win_orange","bomb_planted","bomb_defused","bomb_dropped"]:
		expect(manifest[cue].gain_db==10 and "Kokoro" in manifest[cue].license,"new louder female announcement "+cue)
	var options=Rules.default_options();expect(options.capture_seconds==5,"capture speed defaults to existing five-second neutral capture")
	options.capture_seconds=12;expect(ModeOptions.network(options).capture_seconds==12,"custom capture time survives room network settings")
	options.capture_seconds=0;Rules.sanitize_room(options);expect(options.capture_seconds==1,"capture time cannot be zero")
	options.capture_seconds=100;Rules.sanitize_room(options);expect(options.capture_seconds==60,"capture time upper limit")
	g.zone_capture=[0.,0.,0.];g.zone_owner=[-1,-1,-1];g.options.capture_seconds=10
	for id in g.actors:g.actors[id].position=Vector3(100,0,0)
	g.actors[1].position=Vector3.ZERO;ControlCapture.tick(g,5.)
	expect(is_equal_approx(g.zone_capture[0],2.5) and g.zone_owner[0]==-1,"custom ten-second setting reaches fifty percent after five seconds")
	ControlCapture.tick(g,5.);expect(g.zone_owner[0]==0,"custom setting completes at configured time")
	g.free();print("CAPTURE_V126_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
