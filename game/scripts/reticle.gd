extends Control
var game:Node
var ui:Node
var range_ready=0
var range_m=INF
static func distance_text(meters:float) -> String:
	return "∞ m" if not is_finite(meters) or meters>9999. else "%.1f m"%maxf(0.,meters)
func draw_rangefinder(a:Node,center:Vector2,radius:float):
	# One short-lived measurement, at 10 Hz, only while looking through optics.
	if Time.get_ticks_msec()>=range_ready:
		range_ready=Time.get_ticks_msec()+100
		var eye:Vector3=a.eye();var hit=game.ray(eye,eye+a.direction()*10000.,[a.get_rid()])
		range_m=eye.distance_to(hit.position) if not hit.is_empty() else INF
	var box=Rect2(center+Vector2(radius*.30,-radius*.42),Vector2(radius*.53,radius*.16))
	draw_rect(box,Color(.025,.055,.065,.84));draw_rect(box,Color(.5,.74,.69,.8),false,1.)
	var font_size=clampi(roundi(radius*.07),12,24)
	draw_string(get_theme_default_font(),box.position+Vector2(3,box.size.y*.72),distance_text(range_m),HORIZONTAL_ALIGNMENT_CENTER,box.size.x-6,font_size,Color("c5f2dc"))
func marker_position(actor:Node,camera:Camera3D) -> Vector2:
	var point=actor.character.head.global_position+Vector3.UP*.26 if is_instance_valid(actor.character) and is_instance_valid(actor.character.head) else actor.eye()+Vector3.UP*.20
	if camera.is_position_behind(point):return Vector2.INF
	# Camera projection is in viewport coordinates; the HUD can be independently
	# scaled/offset. Convert to this Control's space before placing the label.
	return get_global_transform_with_canvas().affine_inverse()*camera.unproject_position(point)
func _draw():
	if not game.players.has(game.local_id):return
	var p=game.players[game.local_id]
	if not p.alive or p.flash>game.clock:return
	var a=game.actors[game.local_id];var center=size*.5
	if p.get("cooking",0)>0:
		var seconds=maxf(0.,GrenadeLogic.FUSE-game.clock+float(p.grenade_started));var text="%.1f"%seconds
		var font=get_theme_default_font();draw_string_outline(font,center+Vector2(-70,-35),text,HORIZONTAL_ALIGNMENT_CENTER,140,38,4,Color.BLACK)
		draw_string(font,center+Vector2(-70,-35),text,HORIZONTAL_ALIGNMENT_CENTER,140,38,Color.WHITE)
	var color=Color("d6fff4");var ads=a.input_state.ads and p.slot<2
	var scoped=ads and SniperScope.overlay(game.current_weapon(p)) and p.reload<=game.clock and a.ads_blend>.9
	if scoped:
		var radius=minf(size.x,size.y)*SniperScope.SCREEN_RADIUS
		var reach=maxf(size.x,size.y)*2
		for i in range(96):
			var first=Vector2.from_angle(i*TAU/96.);var next=Vector2.from_angle((i+1)*TAU/96.)
			draw_colored_polygon(PackedVector2Array([center+first*radius,center+first*reach,center+next*reach,center+next*radius]),Color.BLACK)
		draw_circle(center,radius,Color("14212a"),false,4.,true)
		ScopeReticle.draw_on(self,center,radius,game.current_weapon(p))
		draw_rangefinder(a,center,radius)
		if game.current_weapon(p).get("laser",false):
			var heat=clampf(float(p.get("laser_heat",0.)),0.,1.)
			var bar=Rect2(center+Vector2(-radius*.30,radius*.70),Vector2(radius*.60,radius*.035))
			var heat_color=Color("55df75").lerp(Color("ffe251"),heat*2.) if heat<.5 else Color("ffe251").lerp(Color("ff3434"),(heat-.5)*2.)
			draw_rect(bar,Color("233c37"));draw_rect(Rect2(bar.position,Vector2(bar.size.x*heat,bar.size.y)),heat_color)
			if float(p.get("laser_lock",0.))>game.clock:draw_string(get_theme_default_font(),bar.position+Vector2(0,-7),"⚠ 과열",HORIZONTAL_ALIGNMENT_CENTER,bar.size.x,18,Color("ff534a"))
		if MarkerTracker.equipped(p) and game.current_weapon(p).get("category","") in ["저격소총","지정사수소총"]:
			var marking_radius=AimModel.pixel_radius(MarkerTracker.HALF_ANGLE_DEGREES,a.camera.fov,size.y)
			draw_arc(center,marking_radius,0,TAU,96,Color(1.,.86,.36,.28),3.,true)
			var target=int(p.get("marker_target",0))
			if target!=0 and game.actors.has(target):
				var pos=marker_position(game.actors[target],a.camera)
				if pos.is_finite():
					var text="%.1f"%maxf(0.,MarkerTracker.DWELL_SECONDS-float(p.get("marker_progress",0.)))
					draw_string_outline(get_theme_default_font(),pos+Vector2(-35,-12),text,HORIZONTAL_ALIGNMENT_CENTER,70,18,3,Color.BLACK)
					draw_string(get_theme_default_font(),pos+Vector2(-35,-12),text,HORIZONTAL_ALIGNMENT_CENTER,70,18,Color("ffe79d"))
	else:
		var gap=maxf(2.5,AimModel.pixel_radius(a.visual_spread,a.camera.fov,size.y))
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			draw_line(center+direction*gap,center+direction*(gap+6),Color(.015,.035,.04,.8),4.)
			draw_line(center+direction*gap,center+direction*(gap+6),color,2.)
	if not scoped:
		draw_circle(center,2.5,Color(.02,.05,.06,.9));draw_circle(center,1.3,color)
	if Time.get_ticks_msec()<ui.hit_until:
		for d in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:draw_line(center+d*7,center+d*12,Color("ffce7a"),2.,true)
	if game.clock-p.last_hit<.3 and p.protect<game.clock:
		draw_rect(Rect2(Vector2(4,4),size-Vector2(8,8)),Color(.95,.38,.25,.35),false,5.)
