extends SceneTree
# 1.4.5: measures the real pellet pattern of each shotgun (Game.fire) against
# a flat wall at several distances: pellet-end radius from the aim point.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.options.map_random=false;g.options.map=13;g.build_world();g.phase="lobby";g.add_player(1,"TEST","probe_shotgun");g.phase="combat";g.clock=100.
	var p=g.players[1];var actor=g.actors[1]
	p.protect=0.;p.role=2;p.slot=0
	var ends=[];g.set_meta("probe_pellets",ends)
	for wid in ["e1","e2","e3","m3"]:
		var w=Catalog.get_weapon(wid)
		for distance in [4.,8.,15.]:
			var at=Vector3(0,.1,g.arena.bounds.y-7)
			actor.position=at;actor.velocity=Vector3.ZERO;actor.reset_view(0);p.primary=wid;p.fire_ready=0.;p.spray_phase=0.;p.bloom=0.;p.reload=0.;p.alive=true;p.hp=100.;g.equip_ammo(p)
			var wall=g.arena.box(at+Vector3(0,3.,-distance-.5),Vector3(12,8,1),Color.GRAY)
			await physics_frame;await physics_frame
			for i in range(60):actor.simulate(.016,g.clock,false);await physics_frame # spread settles to the standing value
			ends.clear()
			for shot in range(8):
				p.fire_ready=0.;p.spray_phase=0.;p.bloom=0.;p.reload=0.;p.mag[wid]=int(w.mag);g.clock+=1.
				var before=ends.size();g.fire(1)
				if ends.size()==before:print("  no pellets: grounded=%s alive=%s reload=%.1f sprint_release=%.1f last_sprint=%s"%[str(actor.is_on_floor()),str(p.alive),float(p.reload),float(actor.sprint_release),str(actor.last_sprint)])
			var rs=[];var eye=actor.eye()
			for e in ends:rs.append(Vector2(e.x-eye.x,e.y-eye.y).length())
			rs.sort()
			var mean=0.
			for r in rs:mean+=r
			mean/=maxf(1.,rs.size())
			var within10=0
			for r in rs:
				if r<.10:within10+=1
			print("SHOTGUN %s %s at %.0f m spread=%.2f deg (standing %.2f): pellets=%d mean r=%.2f m median=%.2f max=%.2f within10cm=%d%% cone radius=%.2f"%[wid,w.name,distance,float(w.spread),actor.spread_angle,rs.size(),mean,rs[rs.size()/2] if rs.size() else 0.,rs[-1] if rs.size() else 0.,100*within10/maxi(1,rs.size()),(distance+.5)*tan(deg_to_rad(actor.spread_angle))])
			wall.queue_free();await physics_frame
	g.leave_game();g.free();await process_frame
	quit()
