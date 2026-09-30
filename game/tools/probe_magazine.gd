extends SceneTree
# Structure of a gun's Magazine node (and its meshes' materials) after GunModel.build.
func _initialize():call_deferred("run")
func dump(n:Node,depth:int):
	var line="  ".repeat(depth)+n.name+" ("+n.get_class()+")"
	if n is MeshInstance3D:
		line+=" visible=%s mesh=%s override=%s"%[n.visible,n.mesh!=null,str(n.material_override)]
		if n.mesh:line+=" surfaces=%d fmt_color=%s"%[n.mesh.get_surface_count(),str((n.mesh.surface_get_format(0)&Mesh.ARRAY_FORMAT_COLOR)!=0) if n.mesh.get_surface_count()>0 else "-"]
	print("MAG ",line)
	for c in n.get_children():dump(c,depth+1)
func run():
	Catalog.load_all()
	var raw=GunModel.base_scene("Sniper_2").instantiate();root.add_child(raw)
	print("RAW magazine: ",raw.get_node_or_null("Magazine"))
	for c in raw.get_children():print("RAW child ",c.name," ",c.get_class())
	var gun=GunModel.new();gun.build(Catalog.get_weapon(OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "h6"),false);root.add_child(gun)
	if gun.magazine:dump(gun.magazine,0)
	quit()
