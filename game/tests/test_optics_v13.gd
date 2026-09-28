extends SceneTree
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();var styles={};var count=0
	for id in Catalog.weapons:
		var w=Catalog.get_weapon(id)
		if w.get("category","") not in ["저격소총","지정사수소총"]:continue
		styles[ScopeReticle.style(w)]=true
		var weapon=WeaponVisual.new();root.add_child(weapon);weapon.build(w,false,false)
		var scope=weapon.get_node("Scope");var compact=w.name in ["LARK","KESTREL"];var length=.78 if compact else 1.
		assert(scope.get_node("OcularGlass").position.z<.16*length)
		assert(scope.get_node("ObjectiveGlass").position.z>-.19*length)
		assert(scope.get_node("OcularGlass").material_override is ShaderMaterial)
		# Merged housing plus two opaque-coated lenses: bounded draw calls.
		assert(scope.get_child_count()<=3)
		weapon.free();count+=1
	assert(styles.size()==5 and count==5)
	print("OPTICS_V13_PASS weapons=5 unique_reticles=5 recessed_lenses=10");quit()
