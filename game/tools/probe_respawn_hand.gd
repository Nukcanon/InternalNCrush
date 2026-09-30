extends SceneTree
## Debug: respawns the local player through game.spawn() with the other hand
## (right -> left -> right) and captures first person each time, printing the
## view weapon's muzzle direction in camera space (should point to -Z).
var g:Node
func _initialize():call_deferred("run")
func shot(label:String):
	g.ui.refresh()
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/hands2/"+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://../validation/hands2")
	root.size=Vector2i(1280,720)
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=PracticeLayout.INDEX
	g.build_world();g.add_player(1,"PLAYER","hands_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];var a=g.actors[1];a.set_local(true)
	for step in range(6):
		var want=1 if step%2==0 else -1
		for tries in range(200):
			g.spawn(1)
			if int(p.hand)==want:break
		p.protect=0.
		for i in range(30):
			g.clock+=1./60.;a.visual(1./60.,p,g.clock);await process_frame
		var muzzle=a.view_weapon.muzzle.global_position;var grip=a.view_weapon.right_grip.global_position
		var dir=a.camera.global_basis.inverse()*(muzzle-grip).normalized()
		print("RESPAWN step=",step," hand=",p.hand," muzzle_dir_cam=",dir.snapped(Vector3.ONE*.01)," gun_scale=",a.gun.scale," gun_rot=",a.gun.rotation.snapped(Vector3.ONE*.01)," body_scale=",a.view_body.scale.snapped(Vector3.ONE*.01))
		await shot("respawn-hand-%d"%step)
	# Left-handed, then weapons built for the first time (new primary, sidearm).
	for tries in range(200):
		g.spawn(1)
		if int(p.hand)==-1:break
	for spec in [["slot",1],["primary","c1"],["primary","r1"],["slot",0],["role",2],["role",3],["team",1]]:
		if spec[0]=="slot":p.slot=spec[1]
		elif spec[0]=="role":p.role=spec[1];p.primary=Catalog.first(spec[1]);p.slot=0;g.equip_ammo(p)
		elif spec[0]=="team":p.team=spec[1]
		else:p.primary=spec[1];p.slot=0;g.equip_ammo(p)
		for i in range(30):
			g.clock+=1./60.;a.visual(1./60.,p,g.clock);await process_frame
		var muzzle=a.view_weapon.muzzle.global_position;var grip=a.view_weapon.right_grip.global_position
		print("SWITCH ",spec," hand=",p.hand," muzzle_dir_cam=",(a.camera.global_basis.inverse()*(muzzle-grip).normalized()).snapped(Vector3.ONE*.01))
		await shot("respawn-switch-%s"%str(spec[1]))
	quit()
