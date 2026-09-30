extends SceneTree
# Why cover / turret placement is refused at each distance ahead of the engineer.
var g:Node
func _initialize():call_deferred("run")
func reason(kind:String,pos:Vector3,yaw:float,id:int) -> String:
	if not pos.is_finite() or not is_instance_valid(g.arena):return "arena"
	if absf(pos.x)>g.arena.bounds.x-2 or absf(pos.z)>g.arena.bounds.y-2 or g.arena.wading(pos):return "bounds/wading"
	for site in g.arena.sites:
		if site.distance_to(pos)<5.:return "site"
	for spawn in g.arena.ffa_spawns:
		if spawn.distance_to(pos)<2.:return "spawn"
	var query=PhysicsShapeQueryParameters3D.new();var shape=BoxShape3D.new();shape.size=Deployment.size(kind)-Vector3(.04,.04,.04)
	query.shape=shape;query.transform=Transform3D(Basis(Vector3.UP,yaw),pos+Vector3.UP*(Deployment.size(kind).y*.5+.04));query.collision_mask=15
	query.exclude=[g.actors[id].get_rid()]
	var hits=g.get_world_3d().direct_space_state.intersect_shape(query,4)
	if not hits.is_empty():
		var names=[]
		for h in hits:names.append(str(h.collider.name)+"/"+str(h.collider.get_class())+" layer="+str(h.collider.collision_layer))
		return "overlap "+str(names)
	for x in [-.45,.45]:
		for z in [-.45,.45]:
			var point=pos+Basis(Vector3.UP,yaw)*Vector3(x*Deployment.size(kind).x,.2,z*Deployment.size(kind).z)
			var ground=g.ray(point,point-Vector3.UP*.4,[],1)
			if ground.is_empty():return "support none at "+str(point)
			if ground.normal.y<.88:return "support slope "+str(ground.normal)
	return "ok"
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else PracticeLayout.INDEX
	g.build_world();g.add_player(1,"PLAYER","probe")
	g.phase="combat";g.clock=100.
	var p=g.players[1];p.alive=true;p.role=3;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	var spawn:Vector3=g.arena.ffa_spawns[0] if not g.arena.ffa_spawns.is_empty() else Vector3(0,.1,10)
	a.position=Vector3(0,.1,18.) if g.options.map==PracticeLayout.INDEX else spawn+Vector3(0,.1,0)
	a.reset_view(0.);await physics_frame;await physics_frame
	print("actor at ",a.position," eye ",a.eye())
	for kind in ["cover","turret"]:
		for d in [.5,1.,1.5,2.,2.5,3.,4.,5.,6.,7.,8.,9.]:
			var target=a.position+Vector3(0,0,-d)
			var to=target-a.eye()
			a.input_state.pitch=atan2(to.y,Vector2(to.x,to.z).length());a.aim_pitch=a.input_state.pitch
			var c=Deployment.candidate(g,1,kind)
			print("%s d=%.1f hit=%s valid=%s reason=%s"%[kind,d,str(c.pos.snapped(Vector3.ONE*.01)),str(c.valid),reason(kind,c.pos,c.yaw,1)])
	quit()
