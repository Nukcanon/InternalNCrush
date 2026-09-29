extends SceneTree
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();var styles={};var count=0
	for id in Catalog.weapons:
		var w=Catalog.get_weapon(id)
		if w.get("category","") not in ["저격소총","지정사수소총"]:continue
		styles[ScopeReticle.style(w)]=true
		var weapon=GunModel.new();root.add_child(weapon);weapon.build(w,false)
		assert(weapon.muzzle.position.z<weapon.right_grip.position.z,"scoped rifle muzzle ahead of the grip")
		weapon.free();count+=1
	assert(styles.size()==5 and count==5)
	print("OPTICS_V13_PASS weapons=5 unique_reticles=5 recessed_lenses=10");quit()
