extends SceneTree
## Grip fields (1.4.2), step 1 and 3 of tools/bake_grip_fields.py.
##  export: every weapon model's triangles (GunModel space) and its grip
##          handle frames -> validation/grip_fields/export.json
##  pack:   the signed distance grids computed by the Python step
##          -> res://assets/weapons/grip_fields.res (compressed)
## Usage: godot --headless --path game --script res://tools/bake_grip_fields.gd -- export|pack
const WORK="res://../validation/grip_fields/"
const OUT="res://assets/weapons/grip_fields.res"
func _initialize():call_deferred("run")
func visible_chain(node:Node,top:Node) -> bool:
	var n=node
	while n!=null and n!=top:
		if n is Node3D and not (n as Node3D).visible:return false
		n=n.get_parent()
	return true
func run():
	var mode=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "export"
	DirAccess.make_dir_recursive_absolute(WORK)
	if mode=="export":export_all()
	else:pack_all()
	quit()
func export_all():
	var out={}
	Catalog.load_all()
	for wid in Catalog.weapons:
		var w=Catalog.get_weapon(wid)
		var gun=GunModel.new();gun.build(w,false)
		var tris=[]
		for m in gun.find_children("*","MeshInstance3D",true,false):
			if m.mesh==null or not visible_chain(m,gun) or m.has_meta("scope_lens"):continue
			var xf=GunModel.relative(m,gun)
			for f in m.mesh.get_faces():
				var p=xf*f;tris.append_array([snappedf(p.x,.00001),snappedf(p.y,.00001),snappedf(p.z,.00001)])
		var sides={}
		for side in ["R","L"]:
			var g:Node3D=gun.grip(side)
			if g==null:continue
			var h:Transform3D=GunModel.relative(g,gun)
			var b:Basis=h.basis.orthonormalized()
			sides[side]={"scale":h.basis.get_scale().y,"origin":[h.origin.x,h.origin.y,h.origin.z],
				"basis":[b.x.x,b.x.y,b.x.z,b.y.x,b.y.y,b.y.z,b.z.x,b.z.y,b.z.z]}
		out[wid]={"tris":tris,"sides":sides}
		gun.free()
	# 1.4.5: held gear (GadgetVisual in its holder, as Actor.holder_for builds
	# it): one entry per role / variant (and the carried turret), keyed by
	# GadgetVisual.field_key.
	for role in range(6):
		for variant in [0,1,2,8,9]:
			for turret in ([false,true] if role==3 and variant==0 else [false]):
				var key=GadgetVisual.field_key(role,variant,turret)
				var holder=Node3D.new();var item=GadgetVisual.new();holder.add_child(item);item.build(role,variant,true,turret)
				var tris=[]
				for m in item.find_children("*","MeshInstance3D",true,false):
					if m.mesh==null or not visible_chain(m,holder):continue
					var xf=GunModel.relative(m,holder)
					for f in m.mesh.get_faces():
						var p=xf*f;tris.append_array([snappedf(p.x,.00001),snappedf(p.y,.00001),snappedf(p.z,.00001)])
				var sides={"R":item.right_socket}
				if item.two_handed:sides.L=item.left_socket
				var exported={}
				for side in sides:
					var o:Vector3=sides[side]
					exported[side]={"scale":1.,"origin":[o.x,o.y,o.z],"basis":[1,0,0,0,1,0,0,0,1]}
				if not tris.is_empty():out[key]={"tris":tris,"sides":exported}
				holder.free()
	var f=FileAccess.open(WORK+"export.json",FileAccess.WRITE);f.store_string(JSON.stringify(out));f.close()
	print("GRIP_EXPORT ",out.size()," weapons")
func pack_all():
	var index=JSON.parse_string(FileAccess.get_file_as_string(WORK+"fields.json"))
	var fields={}
	for wid in index:
		fields[wid]={}
		for side in index[wid]:
			var e:Dictionary=index[wid][side]
			var data=FileAccess.get_file_as_bytes(WORK+str(e.file))
			fields[wid][side]={"dims":Vector3i(int(e.dims[0]),int(e.dims[1]),int(e.dims[2])),"origin":Vector3(e.origin[0],e.origin[1],e.origin[2]),
				"cell":float(e.cell),"unit":float(e.unit),"data":data}
	var res=Resource.new();res.set_meta("fields",fields)
	var err=ResourceSaver.save(res,OUT,ResourceSaver.FLAG_COMPRESS)
	print("GRIP_PACK ",fields.size()," weapons err=",err)
