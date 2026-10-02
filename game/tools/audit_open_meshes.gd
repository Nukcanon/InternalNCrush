extends SceneTree
# 1.4.10 (the user: railings and boats with faces missing - check every object
# and map model for unclosed meshes): every prop kind (PropCatalog), boat kind
# (BoatModels) and gun is built alone; edges used by one triangle only (after
# welding at 2 mm) are open edges. Prints OPEN lines (kind, open edge length
# and the first places) sorted by length.
func _initialize():call_deferred("run")
func weld(p:Vector3) -> Vector3i:return Vector3i((p*500.).round())
func open_edges(meshes:Array) -> Array:
	var count={};var where={}
	for m in meshes:
		var xf:Transform3D=m[1];var mesh:Mesh=m[0]
		for s in range(mesh.get_surface_count()):
			var arrays=mesh.surface_get_arrays(s);var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var idx=arrays[Mesh.ARRAY_INDEX];var n=idx.size() if idx!=null and idx.size()>0 else v.size()
			for t in range(0,n,3):
				var ids=[idx[t],idx[t+1],idx[t+2]] if idx!=null and idx.size()>0 else [t,t+1,t+2]
				var p=[xf*v[ids[0]],xf*v[ids[1]],xf*v[ids[2]]]
				if (p[1]-p[0]).cross(p[2]-p[0]).length()<1e-7:continue
				for e in range(3):
					var a=weld(p[e]);var b=weld(p[(e+1)%3])
					if a==b:continue
					var key=[a,b] if str(a)<str(b) else [b,a]
					var k=str(key)
					count[k]=int(count.get(k,0))+1;where[k]=[p[e],p[(e+1)%3]]
	var out=[]
	for k in count:
		if int(count[k])==1:out.append(where[k])
	return out
func report(kind:String,meshes:Array,results:Array):
	var edges=open_edges(meshes);var length=0.
	for e in edges:length+=Vector3(e[0]).distance_to(e[1])
	if length>.05:results.append([length,kind,edges.size(),(Vector3(edges[0][0])+Vector3(edges[0][1]))*.5])
func run():
	Catalog.load_all()
	var results=[]
	for kind in PropCatalog.KINDS:
		var k=DistrictFacade.Kit.new();PropCatalog.build(k,kind,7)
		report("prop:"+kind,[[k.detail.commit(),Transform3D()],[k.skin.commit(),Transform3D()]],results)
	for kind in BoatModels.SIZES.keys():
		var k=DistrictFacade.Kit.new();BoatModels.build(k,kind,3,1)
		report("boat:"+kind,[[k.detail.commit(),Transform3D()]],results)
	results.sort_custom(func(a,b):return a[0]>b[0])
	for r in results:print("OPEN %-28s %.2f m in %d edges, e.g. at %s"%[r[1],r[0],r[2],str(Vector3(r[3]).snapped(Vector3.ONE*.01))])
	print("OPEN_KINDS ",results.size())
	quit()
