extends SceneTree
## 1.4: heroes and weapons are baked from their CC0 sources by
## tools/bake_heroes.gd and tools/bake_weapons.gd (sources live outside the
## repository). This step validates the committed bakes, warms the deployable
## templates and writes the model manifest with attribution.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();DirAccess.make_dir_recursive_absolute("res://assets/models")
	var manifest={"license":"Characters: Quaternius Ultimate Modular Men/Women (CC0). Animations: Quaternius Ultimate Modular + Universal Animation Library 1/2 (CC0). Weapons: Quaternius Toon Shooter Game Kit (CC0). See assets/heroes/LICENSE.txt.","operators":[],"weapons":[]}
	for role in range(6):
		var hero=HeroCharacter.new();root.add_child(hero);hero.build(role,0)
		var triangles=0
		for mesh in hero.meshes():
			for s in range(mesh.mesh.get_surface_count()):triangles+=mesh.mesh.surface_get_array_index_len(s)/3
		if hero.skeleton.get_bone_count()<60 or hero.player.get_animation_list().size()<40:printerr("HERO_BAKE_INVALID ",role);quit(1);return
		manifest.operators.append({"role":Rules.CLASSES[role],"identity":HeroCharacter.IDENTITIES[role],"outfit":HeroCharacter.OUTFITS[role],"gender":"female" if role in HeroCharacter.FEMALE_ROLES else "male","height_cm":roundi(HeroCharacter.HEIGHTS[role]*100),"triangles":triangles})
		print("HERO ",role," triangles=",triangles," clips=",hero.player.get_animation_list().size())
		hero.free();await process_frame
	for id in Catalog.weapons:
		var gun=GunModel.new();root.add_child(gun);gun.build(Catalog.get_weapon(id))
		if not is_instance_valid(gun.muzzle) or not is_instance_valid(gun.right_grip):printerr("WEAPON_INVALID ",id);quit(1);return
		manifest.weapons.append({"id":id,"name":Catalog.get_weapon(id).name,"base":str(GunLooks.look(Catalog.get_weapon(id)).get("base",GunLooks.look(Catalog.get_weapon(id)).get("tool","")))})
		gun.free()
	for kind in ["turret","cover"]:
		for team in range(2):
			for variant in ([0,1,2] if kind=="cover" else [1]):
				var probe=Node3D.new();root.add_child(probe);CombatFX.device(probe,kind,team,variant);probe.free()
	var file=FileAccess.open("res://assets/models/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("MODELS_BUILT operators=6 weapons=",Catalog.weapons.size());quit()
