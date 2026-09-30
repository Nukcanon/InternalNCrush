extends SceneTree
## 1.4.2: bakes what the ray fit measures on each hero, so the game only loads it:
##  - the fitted armour per hero and tier (FittedArmor.make_mesh, team colours
##    as the placeholder) -> assets/heroes/armor/<outfit>_<tier>.res
##  - the carried-gear anchor points (CarriedGear.measure) -> carry_points.json
##  - the kit meshes (CarriedGear.make_kit) as named surfaces -> kits.res
## Rerun after a hero rebake or an armour / kit design change
## (tests/test_v142.gd compares the bakes with a fresh fit).
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/heroes/armor")
	var points={}
	for role in range(6):
		var hero=HeroCharacter.new();root.add_child(hero);hero.build(role,0,false)
		var body=FittedArmor.body_of(hero)
		for level in [1,2]:
			var mesh=FittedArmor.make_mesh(hero,body,level)
			if mesh==null:printerr("ARMOR_BAKE_FAILED ",role," ",level);quit(1);return
			var path=FittedArmor.baked_path(role,level)
			var error=ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)
			if error!=OK:printerr("ARMOR_SAVE_FAILED ",path," ",error);quit(1);return
			print("ARMOR_BAKED ",path," vertices=",mesh.surface_get_array_len(0)," indices=",mesh.surface_get_array_index_len(0))
		var measured=CarriedGear.measure(hero)
		if measured.is_empty():printerr("CARRY_POINTS_FAILED ",role);quit(1);return
		points[HeroCharacter.OUTFITS[role]]=CarriedGear.to_json(measured)
		hero.free()
	var file=FileAccess.open(CarriedGear.POINTS_PATH,FileAccess.WRITE);file.store_string(JSON.stringify(points,"\t"));file.close()
	var kits=ArrayMesh.new()
	for kind in CarriedGear.KIT_KINDS:
		var mesh=CarriedGear.make_kit(kind)
		if mesh==null:printerr("KIT_BAKE_FAILED ",kind);quit(1);return
		kits.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh.surface_get_arrays(0));kits.surface_set_name(kits.get_surface_count()-1,kind)
	var error=ResourceSaver.save(kits,CarriedGear.KITS_PATH,ResourceSaver.FLAG_COMPRESS)
	if error!=OK:printerr("KITS_SAVE_FAILED ",error);quit(1);return
	print("KITS_BAKED ",kits.get_surface_count());quit()
