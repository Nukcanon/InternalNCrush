extends SceneTree
# 1.4.5: connected parts of the grenade meshes' surfaces (to split the pull ring).
var parent={}
func root_of(x):
	while parent[x]!=x:
		parent[x]=parent[parent[x]];x=parent[x]
	return x
func _initialize():
	for n in [["Grenade",1],["FireGrenade",2],["FireGrenade",3],["FireGrenade",1]]:
		var src=GunModel.base_scene(n[0]).instantiate()
		var m:MeshInstance3D=src.find_children("*","MeshInstance3D",true,false)[0]
		var arr=m.mesh.surface_get_arrays(n[1]);var v:PackedVector3Array=arr[Mesh.ARRAY_VERTEX];var idx=arr[Mesh.ARRAY_INDEX]
		if idx==null or idx.is_empty():
			idx=PackedInt32Array();for i in range(v.size()):idx.append(i)
		parent={}
		var keys=[]
		for i in range(v.size()):
			var k=v[i].snapped(Vector3.ONE*.0005);keys.append(k);parent[k]=k
		for t in range(0,idx.size(),3):
			var a=root_of(keys[idx[t]])
			for j in [1,2]:
				var b=root_of(keys[idx[t+j]])
				if a!=b:parent[b]=a
		var comps={};var counts={}
		for t in range(0,idx.size(),3):
			var r=root_of(keys[idx[t]])
			if not comps.has(r):comps[r]=AABB(v[idx[t]],Vector3.ZERO);counts[r]=0
			counts[r]+=1
			for j in range(3):comps[r]=comps[r].expand(v[idx[t+j]])
		for r in comps:print("COMP ",n," tris=",counts[r]," ",comps[r])
		src.free()
	quit()
