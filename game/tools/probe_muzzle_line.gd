extends SceneTree
# 1.4.5: does every gun's barrel line run to the crosshair? First person at
# the hip (and aimed): the barrel line (muzzle marker, -Z) against the camera's
# aim ray - where they pass closest, how far apart (m), and the screen offset
# of the barrel line's point at that distance (px from the centre).
var g:Node
func _initialize():call_deferred("run")
func settle(a,p,frames:int=24):
	for i in range(frames):a.visual(1./30.,p,g.clock);await process_frame
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","muzzle_local");g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var worst=0.
	for wid in Catalog.weapons:
		var w=Catalog.get_weapon(wid)
		if w.get("kind","gun")!="gun" or bool(w.get("laser",false)) or GunLooks.look(w).has("tool"):continue
		p.role=maxi(0,int(w.get("role",0)));if int(w.get("slot",0))==1:p.slot=1;p.secondary=wid
		else:p.slot=0;p.primary=wid
		a.shown_weapon="";await settle(a,p)
		for aimed in [false,true]:
			a.input_state.ads=aimed;a.aim_progress=1. if aimed else 0.;a.ads_blend=1. if aimed else 0.
			await settle(a,p,16)
			var gun=a.view_weapon
			if not is_instance_valid(gun) or not is_instance_valid(gun.muzzle):continue
			var m:Vector3=gun.muzzle.global_position;var d:Vector3=-gun.muzzle.global_basis.z.normalized()
			var c:Vector3=a.camera.global_position;var f:Vector3=-a.camera.global_basis.z.normalized()
			# closest points of the two lines
			var w0=m-c;var b=d.dot(f);var dd=d.dot(w0);var e=f.dot(w0);var den=1.-b*b
			var s=(b*e-dd)/den if absf(den)>.000001 else 0.;var t=(e-b*dd)/den if absf(den)>.000001 else 0.
			var pm=m+d*s;var pc=c+f*t
			var gap=pm.distance_to(pc)
			var far=m+d*30.;var px=(a.camera.unproject_position(far)-Vector2(640,360)).length()
			var parallel=absf(den)<.0004
			print("MUZZLE %-14s %s cross_at=%6.2f m gap=%.3f m  30m_px=%5.1f%s"%[wid,"ADS" if aimed else "hip",t,gap,px," (parallel)" if parallel else ""])
			if not aimed:worst=maxf(worst,gap)
		a.input_state.ads=false;a.aim_progress=0.;a.ads_blend=0.
	print("MUZZLE_WORST_HIP_GAP %.3f"%worst)
	quit()
