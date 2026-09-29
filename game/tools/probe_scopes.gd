extends SceneTree
# Lens faces of the baked sniper scopes: vertices whose normal points along
# +-Z above the receiver, grouped by z plane (centre and radius of each).
const TARGETS=[["Sniper","Black",.0],["Sniper_2","DarkGrey",.06]]
func _initialize():
	for target in TARGETS:
		var gun:Node3D=GunModel.base_scene(target[0]).instantiate();root.add_child(gun)
		var m:MeshInstance3D=gun.get_node("Body")
		for s in range(m.mesh.get_surface_count()):
			var mat=m.mesh.surface_get_material(s)
			if mat.resource_name!=target[1]:continue
			var arrays=m.mesh.surface_get_arrays(s)
			var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var n:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var planes={}
			for i in range(v.size()):
				if v[i].y<target[2] or absf(n[i].z)<.7:continue
				var k="%s%.3f"%["F" if n[i].z<0 else "B",v[i].z]
				if not planes.has(k):planes[k]=[99.,-99.,0.,0,n[i]]
				planes[k][0]=minf(planes[k][0],v[i].y);planes[k][1]=maxf(planes[k][1],v[i].y);planes[k][2]=maxf(planes[k][2],absf(v[i].x));planes[k][3]+=1
			for k in planes:print("%s %s y=%.4f..%.4f centre=%.4f halfx=%.4f n=%d normal=%s"%[target[0],k,planes[k][0],planes[k][1],(planes[k][0]+planes[k][1])*.5,planes[k][2],planes[k][3],planes[k][4]])
		gun.queue_free()
	quit()
