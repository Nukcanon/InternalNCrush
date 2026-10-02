extends SceneTree
# 1.5.1 (the user: the new iron sights must not hide the crosshair much while firing
# on and on): every iron-sighted gun aims and fires for 1.5 s; each frame the view
# gun's triangles are projected and a grid of points round the crosshair is tested.
# Prints the worst and the mean share of the crosshair area the gun covers.
var failures=0
var checks=0
const GUNS=["a1","a2","a4","h1","h2","c1","c2","c3","c4","m2"] # (ATLAS aims through its semi-scope view)
const BOX=.03 # half the checked square, in screen heights round the centre
const GRID=11
const WORST_LIMIT=.45
const MEAN_LIMIT=.15
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func coverage(cam:Camera3D,gun:Node3D,size:Vector2) -> float:
	var c=size*.5;var r=size.y*BOX;var pts=[]
	for i in range(GRID):
		for j in range(GRID):pts.append(c+Vector2(lerpf(-r,r,i/float(GRID-1)),lerpf(-r,r,j/float(GRID-1))))
	var hit={}
	for m in gun.find_children("*","MeshInstance3D",true,false):
		if m.mesh==null or not m.is_visible_in_tree():continue
		var xf:Transform3D=m.global_transform
		for s in range(m.mesh.get_surface_count()):
			var arrays=m.mesh.surface_get_arrays(s);var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var idx=arrays[Mesh.ARRAY_INDEX]
			if idx==null or idx.is_empty():idx=range(v.size())
			var screen=PackedVector2Array();var ok=PackedByteArray();screen.resize(v.size());ok.resize(v.size())
			for k in range(v.size()):
				var w=xf*v[k];ok[k]=0 if cam.is_position_behind(w) else 1
				if ok[k]==1:screen[k]=cam.unproject_position(w)
			for t in range(0,idx.size(),3):
				var a=idx[t];var b=idx[t+1];var d=idx[t+2]
				if ok[a]==0 or ok[b]==0 or ok[d]==0:continue
				var p0=screen[a];var p1=screen[b];var p2=screen[d]
				if maxf(p0.x,maxf(p1.x,p2.x))<c.x-r or minf(p0.x,minf(p1.x,p2.x))>c.x+r or maxf(p0.y,maxf(p1.y,p2.y))<c.y-r or minf(p0.y,minf(p1.y,p2.y))>c.y+r:continue
				for n in range(pts.size()):
					if hit.has(n):continue
					if Geometry2D.point_is_inside_triangle(pts[n],p0,p1,p2):hit[n]=true
	return hit.size()/float(pts.size())
func run():
	Catalog.load_all()
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(5):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.map=0
	g.build_world();g.add_player(1,"TEST","sight_v151");g.phase="combat";g.clock=100.
	var p=g.players[1];p.alive=true;p.protect=0.;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.reset_view(0)
	var size:Vector2=a.camera.get_viewport().get_visible_rect().size
	var step=1./60.
	for wid in GUNS:
		var w=Catalog.get_weapon(wid);p.role=maxi(0,int(w.get("role",0)));p.slot=0;p.primary=wid;p.mag[wid]=999;a.shown_role=-1;a.shown_weapon=""
		a.input_state.ads=false;a.aim_progress=0.
		for i in range(30):g.clock+=step;a.visual(step,p,g.clock)
		a.input_state.ads=true
		for i in range(40):a.aim_progress=minf(1.,a.aim_progress+.05);g.clock+=step;a.visual(step,p,g.clock)
		var rest=coverage(a.camera,a.view_weapon,size)
		var next=g.clock;var worst=0.;var total=0.;var frames=0
		for i in range(90):
			if g.clock>=next:p.shot_time=g.clock;next+=float(w.get("interval",.1))
			g.clock+=step;a.visual(step,p,g.clock)
			if i%3==0:
				var cov=coverage(a.camera,a.view_weapon,size);worst=maxf(worst,cov);total+=cov;frames+=1
		var mean=total/maxi(1,frames)
		print("SIGHT %s rest %.2f firing worst %.2f mean %.2f"%[w.name,rest,worst,mean])
		expect(worst<=WORST_LIMIT and mean<=MEAN_LIMIT,"%s: firing, its sights cover at most %d%% (mean %d%%) of the crosshair area"%[w.name,roundi(worst*100.),roundi(mean*100.)])
		a.input_state.ads=false;a.aim_progress=0.
	print("SIGHT_CLEARANCE_RESULT %d/%d"%[checks-failures,checks])
	quit(1 if failures>0 else 0)
