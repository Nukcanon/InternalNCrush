extends SceneTree
# Debug: first-person view after a role change (wrench / grenade were invisible).
var g:Node
func _initialize():call_deferred("run")
func settle(a,frames:int=20):
	for i in range(frames):a.visual(1./30.,g.players[a.pid],g.clock);await process_frame
func dump(a,label:String):
	var vb=a.view_body
	print("== ",label)
	print(" view_body valid=",is_instance_valid(vb)," visible=",vb.visible if is_instance_valid(vb) else "-"," pos_cam=",a.camera.to_local(vb.global_position) if is_instance_valid(vb) else "-"," held=",vb.held if is_instance_valid(vb) else "-")
	if is_instance_valid(vb):
		var arms=vb.skeleton.get_node_or_null("FPArms");print(" FPArms=",arms," visible=",arms.visible if arms else "-"," in_tree=",arms.is_visible_in_tree() if arms else "-")
		print(" wrist_R cam=",a.camera.to_local(vb.bone_world(vb.bone["Wrist.R"]).origin)," shoulder_R cam=",a.camera.to_local(vb.bone_world(vb.bone["UpperArm.R"]).origin))
	print(" melee_view=",a.melee_view," visible=",a.melee_view.visible if is_instance_valid(a.melee_view) else "-"," parent=",a.melee_view.get_parent().name if is_instance_valid(a.melee_view) else "-"," cam=",a.camera.to_local(a.melee_view.global_position) if is_instance_valid(a.melee_view) else "-")
	print(" view_item=",a.view_item," visible=",a.view_item.visible if is_instance_valid(a.view_item) else "-"," cam=",a.camera.to_local(a.view_item.global_position) if is_instance_valid(a.view_item) else "-"," item_model.visible=",a.item_model.visible)
	print(" view_weapon=",a.view_weapon," visible=",a.view_weapon.visible if is_instance_valid(a.view_weapon) else "-")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","v14_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=0;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	await settle(a);dump(a,"rifle")
	p.slot=MeleeCombat.SLOT;await settle(a);dump(a,"knife")
	p.role=3;a.set_team(0);await settle(a);dump(a,"wrench after role change")
	p.role=0;a.set_team(0);p.slot=2;p.gadget=1;p.cooking=1;p.grenade_started=g.clock-.4;await settle(a);dump(a,"grenade after role change")
	p.cooking=0;p.erase("grenade_started");p.slot=0;await settle(a);dump(a,"rifle again")
	p.slot=2;p.cooking=1;p.grenade_started=g.clock-.4;await settle(a);dump(a,"grenade without role change")
	quit()
