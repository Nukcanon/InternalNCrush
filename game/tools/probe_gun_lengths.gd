extends SceneTree
## Debug: overall length / height of every weapon (gun-node space, metres), its
## base and look scale, grip-to-muzzle distance and the support grip position.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	for wid in Catalog.weapons:
		var w=Catalog.get_weapon(wid)
		var gun=GunModel.new();root.add_child(gun);gun.build(w,false)
		var box=AABB();var first=true
		for m in gun.find_children("*","MeshInstance3D",true,false):
			if not m.is_visible_in_tree() or m.mesh==null:continue
			var b=GunModel.relative(m,gun)*m.get_aabb();box=b if first else box.merge(b);first=false
		var look=GunLooks.look(w);var s=gun.base.scale.x
		print("GUN %-12s %-9s base=%-14s scale=%.2f len=%.3f h=%.3f w=%.3f grip_z=%.3f fore_z=%.3f muzzle_z=%.3f mag=%s dmg=%s" % [wid,w.name,str(look.get("base",look.get("launcher",look.get("tool","")))),s,box.size.z,box.size.y,box.size.x,gun.right_grip.position.z*s,gun.left_grip.position.z*s,gun.muzzle.position.z*s,str(is_instance_valid(gun.magazine)),str(w.damage)])
		gun.free()
	quit()
