extends SceneTree
## Debug: first-use costs of the carried gear (layout fit, weapon merge, kit).
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	for role in range(6):
		var h=HeroCharacter.new();root.add_child(h);h.build(role,0,false)
		var t0=Time.get_ticks_usec();CarriedGear.layout(h);var t1=Time.get_ticks_usec()
		CarriedGear.weapon_mesh(Catalog.get_weapon(Catalog.first(role)),false);var t2=Time.get_ticks_usec()
		var gun=GunModel.new();gun.build(Catalog.get_weapon(Catalog.list_for(role)[-1]),false);var t3=Time.get_ticks_usec();gun.free()
		print("COST role=",role," layout=",(t1-t0)/1000.," merge=",(t2-t1)/1000.," gunmodel=",(t3-t2)/1000.)
		h.free()
	var t=Time.get_ticks_usec()
	for kind in ["frag","cluster","smoke","flash","medkit","defuse","holster","marker","plates3","covers1"]:CarriedGear.kit_mesh(kind)
	print("COST kits=",(Time.get_ticks_usec()-t)/1000.)
	quit()
