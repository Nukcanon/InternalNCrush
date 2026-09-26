extends SceneTree
const OUT="res://../validation/v120/"
var g:Node
func _initialize():call_deferred("run")
func capture(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(OUT+name+".jpg",.94)
func run():
	root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(OUT)
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false;g.arena.box(Vector3(0,-.5,-35),Vector3(200,1,200),Color("727c85"))
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("364c62");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.9;g.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,-20,0);g.add_child(light)
	for id in [1,2,3,4]:g.add_player(id,"Builder%d"%id,"builder%d"%id);g.players[id].team=0;g.players[id].protect=0.;g.actors[id].position=Vector3(30+id,0,30)
	g.phase="combat";g.clock=100.;var p=g.players[1];p.role=3;p.primary="e1";p.skill_ready=0.;var a=g.actors[1];a.position=Vector3.ZERO;a.set_local(true);a.reset_view(.2)
	for id in [1,2]:g.devices[id]={"kind":"turret","owner":id,"team":0,"pos":Vector3(1.8,0,-3) if id==1 else Vector3(-.8,0,-3.7),"yaw":0.,"level":1,"hp":180.,"max_hp":180.,"upgrade_ready":0.,"building_until":0.,"expires":300.,"disabled":0.}
	await physics_frame;await physics_frame
	g.ui.show_hud();g.update_world_visuals(0.);g.ui.refresh();await capture("turret-ready")
	p.skill_ready=130.;g.update_world_visuals(0.);g.ui.refresh();await capture("turret-cooldown")
	for did in g.devices.keys():g.remove_device(did)
	p.role=5;p.primary="m3";p.skill_ready=0.;a.reset_view(0.)
	for id in [2,3,4]:
		var b=g.actors[id];b.position=[Vector3(-1.5,0,-5),Vector3(0,0,-20),Vector3(10,0,-60)][id-2];g.players[id].hp=[100.,50.,10.][id-2];b.visual(.016,g.players[id],g.clock)
	g.ui.refresh();await capture("medic-health-distances")
	p.invul_select=110.;g.actors[3].visual(.016,g.players[3],g.clock);await capture("medic-target")
	g.ui.gear();g.ui.gear_category=0;g.ui.preview_kind=1;g.ui.gear_primary.select(g.ui.weapon_ids.find("m3"));g.ui.refresh_gear_detail();g.ui.refresh_gear_cards();await capture("mender-card")
	g.ui.gear_category=2;g.ui.preview_kind=2;g.ui.gear_gadget.select(g.ui.gear_gadget.get_item_index(8));g.ui.refresh_gear_detail();g.ui.refresh_gear_cards();await capture("frag-card")
	g.free();await process_frame;print("V120_REVIEW_OK");quit()
