extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if ok:print("PASS ",message)
	else:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	expect(Rules.MAPS.size()==19,"nineteen distinct named maps registered")
	for capacity in [6,8,16,32]:expect(Rules.maps_for_size(capacity).size()=={6:6,8:6,16:4,32:3}[capacity],"map count for "+str(capacity)+" players")
	for index in range(6,Rules.MAPS.size()):
		var arena=Arena.new();root.add_child(arena);arena.build(index);var nav=BotNavigation.new();nav.build(arena)
		var clear=true;var connected=true
		for team in [0,1]:
			var candidates=arena.spawn_candidates(team,false)
			clear=clear and candidates.size()>=7
			for pos in candidates:clear=clear and arena.point_clear(pos) and absf(pos.z)<=arena.bounds.y-6
			for zone in arena.zones:
				connected=connected and arena.point_clear(zone) and nav.route(candidates[0],zone).size()>1 and nav.point(nav.nearest(zone)).distance_to(zone)<3.
		expect(clear,"map "+str(index)+" bounded clear spawn region")
		expect(connected,"map "+str(index)+" both teams reach all objectives")
		arena.queue_free();await process_frame;await process_frame
	expect(DamageIndicator.screen_direction(Vector3.FORWARD,0).distance_to(Vector2.UP)<.001,"front hit draws at screen top")
	expect(DamageIndicator.screen_direction(Vector3.RIGHT,0).distance_to(Vector2.RIGHT)<.001,"right hit draws on right")
	expect(DamageIndicator.screen_direction(Vector3.BACK,0).distance_to(Vector2.DOWN)<.001,"rear hit draws at bottom")
	expect(DamageIndicator.screen_direction(Vector3.LEFT,PI/2).distance_to(Vector2.UP)<.001,"hit direction follows camera rotation")
	var indicator=DamageIndicator.new();root.add_child(indicator);indicator.register_hit(Vector3.FORWARD,20,0.);indicator.register_hit(Vector3.FORWARD,10,.1)
	expect(indicator.hits.size()==1,"same direction merges pellet damage")
	for i in range(20):indicator.register_hit(Vector3(cos(i),0,sin(i)),10,0)
	expect(indicator.hits.size()<=DamageIndicator.MAX_HITS,"direction indicator history is bounded")
	indicator.clear_hits();indicator.register_hit(Vector3.RIGHT,10,-10.);indicator._process(0);expect(indicator.hits.is_empty(),"damage arcs expire after their lifetime");indicator.queue_free()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.server=true;g.phase="lobby";g.options.map=7;g.build_world();g.add_player(1,"motion","v06_host");g.local_id=1;var a=g.actors[1];a.set_local(true);a.visual(.016,g.players[1],g.clock)
	var before=g.combat_fx.casings.size();expect(a.show_shot(100.),"new shot adds recoil");expect(not a.show_shot(100.),"snapshot and event do not duplicate shot effects")
	expect(a.recoil>0 and g.combat_fx.casings.size()==before+1,"local shot emits a casing and a visible kick")
	for i in range(80):g.combat_fx.eject_case(Vector3.UP,Vector3.RIGHT,Vector3.UP,0,i)
	expect(g.combat_fx.casings.size()==CombatFX.MAX_CASINGS,"case pool remains bounded")
	g.combat_fx._process(CombatFX.CASING_LIFETIME+.1);expect(g.combat_fx.casings.is_empty(),"casings disappear after their lifetime")
	var old_position=a.position;var old_gait=a.gait
	a.input_state.z=0.;a.simulate(.016,g.clock,false);expect(a.gait==old_gait,"standing still does not advance foot cycle")
	a.position=Vector3.ZERO;a.input_state.z=-1.;await physics_frame
	for i in range(20):a.simulate(.016,g.clock,true);await physics_frame
	expect(a.gait>old_gait,"actual ground travel advances locomotion phase")
	var character=a.character;character.motion_seed=0.;character.update_pose(.1,Vector3.ZERO,false,false,true,0,-1,0);var chest_a=character.chest.rotation
	character.motion_seed=2.;character.update_pose(.1,Vector3.ZERO,false,false,true,0,-1,0);expect(chest_a!=character.chest.rotation,"idle variation differs across character seeds")
	g.ui.damage_indicator.clear_hits();g.damage_notice(2,Vector3.RIGHT,20,false);expect(g.ui.damage_indicator.hits.is_empty(),"damage feedback ignores other players")
	g.damage_notice(1,a.position+Vector3.RIGHT*4,20,false);expect(g.ui.damage_indicator.hits.size()==1,"local damage receives direction feedback")
	expect(g.audio_bank.catalog.has("hurt") and g.audio_bank.catalog.has("armor_hurt"),"separate incoming damage sounds exist")
	expect(g.audio_bank.category_gain("combat")==1.,"incoming damage follows fixed combat category")
	g.ui.damage_indicator.clear_hits();g.players[1].protect=0.;g.damage(1,1,0,false,"turret",a.position+Vector3.LEFT*5)
	expect(g.ui.damage_indicator.hits.size()==1 and Vector3(g.ui.damage_indicator.hits[0].direction).dot(Vector3.LEFT)>.99,"turret damage uses projectile origin, not owner position")
	g.leave_game();await create_timer(.15).timeout;g.queue_free();await process_frame;await process_frame
	print("V06_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
