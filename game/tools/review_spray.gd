extends SceneTree
# 1.5.4 (the user: a CS-style "T" spray): every gun fires a whole magazine at a wall 10 m
# away, standing still, through game.fire (the server's own aim, cone and pattern); the
# holes are drawn on one card per gun, numbered by colour from the first round (white) to
# the last (red), with the crosshair at the centre. Also a tap-fired run (3-round bursts).
# Output: validation/spray/<id>.png and a contact sheet validation/spray/all.png.
const WALL=10.
const PX=30. # pixels per degree on the cards
const CARD=Vector2i(330,380)
var g:Node
func _initialize():call_deferred("run")
func shoot(wid:String,taps:bool) -> Array:
	var p=g.players[1];var a=g.actors[1];var w=Catalog.get_weapon(wid)
	p.role=maxi(0,int(w.get("role",0)));p.slot=0 if int(w.get("slot",0))==0 else 1
	if p.slot==0:p.primary=wid
	else:p.secondary=wid
	p.mag[wid]=int(w.mag);p.reload=0.;p.fire_ready=0.;p.bloom=0.;p.spray_phase=0.;p.spray_index=0;p.shot_time=-100.;p.switch_until=0.;p.melee_started=-100.
	a.aim_yaw=0.;a.aim_pitch=0.;a.input_state.yaw=0.;a.input_state.pitch=0.;a.velocity=Vector3.ZERO;a.input_state.ads=false;a.input_state.crouch=false;a.aim_progress=0.
	a.spread_angle=AimModel.spread(w,0.,false,false,false,true,0.)
	var holes=[];var step=1./120.;var shots=0;var pause_until=0.
	var probe=[];g.set_meta("probe_pellets",probe)
	while shots<int(w.mag) and holes.size()<int(w.mag):
		g.clock+=step
		AimModel.recover(p,w,step,g.clock)
		a.update_spread(step,g.clock)
		if g.clock>=float(p.fire_ready) and g.clock>=pause_until:
			var before=probe.size();g.fire(1)
			if probe.size()>before:
				shots+=1
				for end in probe.slice(before):holes.append(end)
				if taps and shots%3==0:pause_until=g.clock+.45
	g.remove_meta("probe_pellets")
	return holes
func card(wid:String,holes:Array,label:String) -> Image:
	var img=Image.create(CARD.x,CARD.y,false,Image.FORMAT_RGBA8);img.fill(Color("ece6d8"))
	var c=Vector2(CARD.x*.5,CARD.y*.8)
	for d in range(-6,7):
		var col=Color(0,0,0,.10) if d!=0 else Color(0,0,0,.25)
		for i in range(CARD.y):img.set_pixel(clampi(int(c.x+d*PX),0,CARD.x-1),i,col.blend(img.get_pixel(clampi(int(c.x+d*PX),0,CARD.x-1),i)) if d%2==0 else img.get_pixel(clampi(int(c.x+d*PX),0,CARD.x-1),i))
	for k in range(-8,9):
		img.set_pixel(int(c.x)+k,int(c.y),Color(.1,.6,.5));img.set_pixel(int(c.x),int(c.y)+k,Color(.1,.6,.5))
	for i in range(holes.size()):
		var h:Vector3=holes[i]
		var deg=Vector2(rad_to_deg(atan2(h.x,WALL)),rad_to_deg(atan2(h.y-g.actors[1].eye().y,WALL)))
		var at=c+Vector2(deg.x,-deg.y)*PX
		var t=float(i)/maxf(1.,holes.size()-1.)
		var col=Color(1,1,1).lerp(Color(.85,.12,.1),t) if i>0 else Color(.1,.45,1.)
		for dy in range(-3,4):
			for dx in range(-3,4):
				if dx*dx+dy*dy<=9:
					var q=Vector2i(int(at.x)+dx,int(at.y)+dy)
					if q.x>=0 and q.y>=0 and q.x<CARD.x and q.y<CARD.y:img.set_pixelv(q,Color(.1,.1,.12) if dx*dx+dy*dy>=6 else col)
	return img
func run():
	root.size=Vector2i(800,600);Catalog.load_all()
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(5):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(60,60);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(120,1,120),Color.GRAY);g.arena.box(Vector3(0,5,-WALL-.5),Vector3(40,12,1),Color.GRAY)
	g.add_player(1,"Sprayer","s");g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0
	var a=g.actors[1];a.position=Vector3.ZERO;a.last_sprint=false;a.sprint_release=0.
	for i in range(3):await physics_frame
	DirAccess.make_dir_recursive_absolute("res://../validation/spray/")
	var only=Array(OS.get_cmdline_user_args()).filter(func(x):return str(x).begins_with("--only="))
	var ids=[]
	for id in Catalog.weapons:
		var w=Catalog.get_weapon(id)
		if w.kind!="gun" or w.get("laser",false) or w.get("rocket",false) or int(w.pellets)>1:continue
		if not only.is_empty() and not id in str(only[0]).trim_prefix("--only=").split(","):continue
		ids.append(id)
	var sheet=Image.create(CARD.x*6,CARD.y*ceili(ids.size()/6.),false,Image.FORMAT_RGBA8);sheet.fill(Color("ece6d8"))
	for n in range(ids.size()):
		var id=ids[n];var w=Catalog.get_weapon(id)
		var holes=shoot(id,"taps" in OS.get_cmdline_user_args())
		var img=card(id,holes,w.name);img.save_png("res://../validation/spray/%s.png"%id)
		sheet.blit_rect(img,Rect2i(Vector2i.ZERO,CARD),Vector2i((n%6)*CARD.x,(n/6)*CARD.y))
		print("SPRAY %s %d rounds"%[w.name,holes.size()])
	sheet.save_png("res://../validation/spray/all%s.png"%("_taps" if "taps" in OS.get_cmdline_user_args() else ""))
	quit()
