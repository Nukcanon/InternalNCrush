extends SceneTree
# Cost of the finger grip solver: first solve (cache miss) per weapon and the
# per-frame cost of posing heroes once cached.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	for id in ["a1","pistol","e1","h5","dual_pistols"]:
		var w=Catalog.get_weapon(id)
		var gun=GunModel.new();gun.build(w,false);hero.hold(gun)
		var kind=GunLooks.hold_kind(w);if kind=="shoulder":kind="rifle"
		var s={"hold":kind,"hands":1.,"two_hands":kind!="pistol" or bool(w.get("dual",false))}
		var t0=Time.get_ticks_usec();hero.drive(1./60.,s);var first=Time.get_ticks_usec()-t0
		t0=Time.get_ticks_usec()
		for i in range(60):hero.drive(1./60.,s)
		var cached=(Time.get_ticks_usec()-t0)/60.
		print("BENCH %s first=%.1fms cached=%.3fms/frame"%[id,first/1000.,cached/1000.])
		gun.queue_free();await process_frame
	# Cost without the grip (hands 0) for comparison.
	var t1=Time.get_ticks_usec()
	for i in range(60):hero.drive(1./60.,{"hold":"none","hands":0.})
	print("BENCH no-hands %.3fms/frame"%((Time.get_ticks_usec()-t1)/60000.))
	quit()
