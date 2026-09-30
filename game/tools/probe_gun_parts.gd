extends SceneTree
## Connected pieces of each Toon Shooter gun source (welded by position): size
## and place of every piece in the baked frame (muzzle -Z, butt +Z, metres), to
## find which pieces are the magazine (tools/bake_weapons.gd).
const Bake=preload("res://tools/bake_weapons.gd")
func _initialize():call_deferred("run")
func run():
	var only=OS.get_cmdline_user_args()
	for base in Bake.BASES:
		if not only.is_empty() and not base in only:continue
		probe(base,Bake.BASES[base])
	quit()
func probe(base:String,spec:Dictionary):
	var doc=GLTFDocument.new();var state=GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(Bake.DIR+base+".gltf"),state)!=OK:print("missing ",base);return
	var scene:Node3D=doc.generate_scene(state);root.add_child(scene)
	var vertical=bool(spec.get("vertical",false))
	var turn=Basis.IDENTITY if vertical else Basis(Vector3.UP,-PI/2)
	var tris=[] # [p0,p1,p2,material]
	for mesh_node in scene.find_children("*","MeshInstance3D",true,false):
		var xf:Transform3D=mesh_node.global_transform
		for s in range(mesh_node.mesh.get_surface_count()):
			var arrays=mesh_node.mesh.surface_get_arrays(s);var mat=mesh_node.mesh.surface_get_material(s)
			var name=mat.resource_name if mat else "Material"
			var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var idx=arrays[Mesh.ARRAY_INDEX]
			if idx==null or idx.is_empty():idx=range(v.size())
			for i in range(0,idx.size(),3):tris.append([turn*(xf*v[idx[i]]),turn*(xf*v[idx[i+1]]),turn*(xf*v[idx[i+2]]),name])
	scene.queue_free()
	var lo=Vector3.INF;var hi=-Vector3.INF
	for t in tris:
		for k in range(3):lo=lo.min(t[k]);hi=hi.max(t[k])
	var size=hi-lo;var along=size.y if vertical else size.z
	var scale=float(spec.length)/along
	# Union-find over welded vertices.
	var ids={};var parent=[]
	var key=func(p:Vector3) -> String:return str(p.snapped(Vector3.ONE*.0005))
	var find=func(i:int) -> int:
		while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
		return i
	var tri_ids=[]
	for t in tris:
		var v=[]
		for k in range(3):
			var kk=key.call(t[k])
			if not ids.has(kk):ids[kk]=parent.size();parent.append(parent.size())
			v.append(ids[kk])
		for k in range(1,3):
			var a=find.call(v[0]);var b=find.call(v[k])
			if a!=b:parent[a]=b
		tri_ids.append(v[0])
	var groups={}
	for i in range(tris.size()):
		var g=find.call(tri_ids[i])
		if not groups.has(g):groups[g]={"n":0,"lo":Vector3.INF,"hi":-Vector3.INF,"mats":{}}
		var G=groups[g];G.n+=1;G.mats[tris[i][3]]=true
		for k in range(3):G.lo=G.lo.min(tris[i][k]);G.hi=G.hi.max(tris[i][k])
	print("== ",base," pieces ",groups.size()," tris ",tris.size()," extent(u along z) lo ",lo," hi ",hi," scale ",snappedf(scale,.001))
	var list=groups.values();list.sort_custom(func(a,b):return a.n>b.n)
	for G in list:
		var u0=inverse_lerp(lo.z,hi.z,G.lo.z);var u1=inverse_lerp(lo.z,hi.z,G.hi.z)
		var v0=inverse_lerp(lo.y,hi.y,G.lo.y);var v1=inverse_lerp(lo.y,hi.y,G.hi.y)
		var w0=inverse_lerp(lo.x,hi.x,G.lo.x);var w1=inverse_lerp(lo.x,hi.x,G.hi.x)
		print("  tris %4d u %.2f-%.2f v %.2f-%.2f w %.2f-%.2f size(m) %s mats %s"%[G.n,u0,u1,v0,v1,w0,w1,str(((G.hi-G.lo)*scale).snapped(Vector3.ONE*.001)),str(G.mats.keys())])
