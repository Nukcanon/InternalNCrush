extends SceneTree
# 1.4.10 (the user: the pin-pulling hand sinks into the throwable): how deep the free
# hand's joints (and points along its palm and finger bones) go into the throwable's
# body during the pin pull, frame by frame. Args: role=N gadget=N shots
# (the body is taken as a cylinder round its AABB - the lever widens it, so depths read high)
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","pin_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var role=4;var gadget=1;var shots=false
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("role="):role=int(str(arg).substr(5))
		if str(arg).begins_with("gadget="):gadget=int(str(arg).substr(7))
		if str(arg)=="shots":shots=true
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=role;p.primary=Catalog.first(role);p.secondary="pistol";p.slot=2;p.gadget=gadget;p.team=0;p.gadget_count=3;p.flash_count=3;p.smoke=3
	var a=g.actors[1];a.shown_role=-1;a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var step=1./60.
	for i in range(60):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	var configs=[{}]
	configs_size=configs.size()
	for cfg in configs:
		p.cooking=0;p.erase("throw_until")
		for i in range(30):g.clock+=step;a.visual(step,p,g.clock);await process_frame
		await cycle(a,p,step,shots,cfg)
	quit()
var configs_size=1
func cycle(a,p,step,shots,cfg):
	var worst=0.;var total=0.;var frames=0;var elbow_top=-9.
	for i in range(60):
		if i==5:p.cooking=1;p.grenade_started=g.clock
		g.clock+=step;a.visual(step,p,g.clock);await process_frame
		if shots and i in [12,18,22,26,30]:
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://../validation/throw-pin/");root.get_texture().get_image().save_jpg("res://../validation/throw-pin/p%02d.jpg"%i,.85)
		var payload=a.cached_child(a.view_item,"Payload") if is_instance_valid(a.view_item) else null
		var body:Node3D=payload.get_node_or_null("Grenade") if payload else null
		if body==null:continue
		var box=AABB();var first=true
		for m in body.find_children("*","MeshInstance3D",true,false):
			if m.name=="PullRing" or not m.visible or m.mesh==null:continue
			var bb=GunModel.relative(m,body)*m.get_aabb();box=bb if first else box.merge(bb);first=false
		var inv=body.global_transform.affine_inverse();var sc=body.global_basis.get_scale()
		var b=a.view_body;var chains=HeroIK.finger_chains(b,"L");var wrist=b.bone_world(b.bone["Wrist.L"]).origin
		var pts=[]
		for f in chains:
			var prev=wrist
			for bone in chains[f]:
				var at=b.bone_world(bone).origin
				for k in range(4):pts.append(prev.lerp(at,k/4.))
				prev=at
			pts.append(prev)
		var c=box.get_center();var half=box.size*.5;var radius=minf(half.x,half.z)
		var deep=0.;var inside=0;var who={}
		var names=[];for f in chains:
			for k in range(chains[f].size()*4+1):names.append(f)
		for qi in range(pts.size()):
			var q=pts[qi]
			var l:Vector3=inv*q;var radial=Vector2(l.x-c.x,l.z-c.z).length()
			var pen=minf(radius-radial,half.y-absf(l.y-c.y))*sc.x+.008 # finger thickness
			if pen>0.:inside+=1;deep=maxf(deep,pen);who[names[qi]]=maxf(who.get(names[qi],0.),pen*1000.)
		var age=g.clock-float(p.get("grenade_started",g.clock))
		if p.cooking>0 and age<Actor.PIN_PULL+.05:elbow_top=maxf(elbow_top,(a.camera.global_transform.affine_inverse()*b.bone_world(b.bone["LowerArm.L"]).origin).y)
		var ring=body.get_node_or_null("PullRing")
		if i==6 and ring:
			var vs=a.view_space.global_transform.affine_inverse()
			print("RINGBOX ",GunModel.relative(ring,body)*ring.get_aabb()," scale ",body.global_basis.get_scale());print("GEOM box ",box," ring(body) ",GunModel.relative(ring,body)*Actor.ring_centre(ring)," ring(view) ",vs*(ring.global_transform*Actor.ring_centre(ring))," centre(view) ",vs*(body.global_transform*c)," axis(view) ",(vs.basis*body.global_basis.y).normalized()," wrist(view) ",vs*wrist)
		if p.cooking>0 and age<Actor.PIN_PULL+.05:
			if configs_size<=1:print("PIN f%02d age %.2f inside %d deep %.1f mm r %.1f mm h %.1f mm %s"%[i,age,inside,deep*1000.,radius*sc.x*1000.,half.y*sc.x*1000.,str(who)])
			worst=maxf(worst,deep);total+=deep;frames+=1
	print("PIN_RESULT worst %.1f mm mean %.1f mm frames %d elbow_y %.3f %s"%[worst*1000.,total*1000./maxi(1,frames),frames,elbow_top,str(cfg)])
