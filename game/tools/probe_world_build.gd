extends SceneTree
# Timing of the pieces of Game.build_world for one map (arg: map).
func _initialize():call_deferred("run")
func run():
	var index=int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 7
	for i in range(3):await process_frame
	var t=Time.get_ticks_msec()
	CombatFX.prepare_devices();print("WB prepare_devices %d ms"%(Time.get_ticks_msec()-t));t=Time.get_ticks_msec()
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(3):await process_frame
	t=Time.get_ticks_msec();Construction.prepare(g);print("WB construction.prepare %d ms"%(Time.get_ticks_msec()-t));t=Time.get_ticks_msec()
	var packed=load("res://assets/arenas/complete/map_%02d.scn"%index)
	print("WB load scn %d ms exists=%s"%[Time.get_ticks_msec()-t,str(packed!=null)]);t=Time.get_ticks_msec()
	var arena=Arena.new();root.add_child(arena);arena.build(index)
	print("WB arena.build %d ms cached_nav=%s building=%s"%[Time.get_ticks_msec()-t,str(arena.has_meta("navigation_cache")),str(arena.building)]);t=Time.get_ticks_msec()
	var nav=BotNavigation.new();nav.build(arena)
	print("WB navigation.build %d ms grid=%s"%[Time.get_ticks_msec()-t,str(nav.grid.region.size)]);t=Time.get_ticks_msec()
	var markers=ObjectiveMarkers.new();arena.add_child(markers)
	print("WB markers %d ms"%(Time.get_ticks_msec()-t));t=Time.get_ticks_msec()
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	print("WB hero.build %d ms"%(Time.get_ticks_msec()-t));t=Time.get_ticks_msec()
	var hero2=HeroCharacter.new();root.add_child(hero2);hero2.build(3,1,false)
	print("WB second hero (other role) %d ms"%(Time.get_ticks_msec()-t));t=Time.get_ticks_msec()
	var gun=GunModel.new();root.add_child(gun);gun.build(Catalog.get_weapon("a1"),true)
	print("WB gun a1 %d ms"%(Time.get_ticks_msec()-t));t=Time.get_ticks_msec()
	var gun2=GunModel.new();root.add_child(gun2);gun2.build(Catalog.get_weapon("e1"),true)
	print("WB gun e1 %d ms"%(Time.get_ticks_msec()-t));t=Time.get_ticks_msec()
	var c=GripField.contact(gun,gun.right_grip.global_transform)
	print("WB grip field a1 %d ms keys=%s"%[Time.get_ticks_msec()-t,str(c.keys())]);t=Time.get_ticks_msec()
	await process_frame
	print("WB first frame after builds %d ms"%(Time.get_ticks_msec()-t))
	quit()
