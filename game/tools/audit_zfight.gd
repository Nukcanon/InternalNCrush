extends SceneTree
# 1.4.7 (the user: two materials on the same plane flicker by angle): faces of
# different meshes or colours lying in the same plane (within 6 mm) and
# overlapping by more than MIN_AREA. Builds each map as the bake does and
# prints ZFIGHT lines (location, the two sources). Args: map indices.
const MIN_AREA=.02
const SLAB=.006
var found=0
func _initialize():call_deferred("run")
func label(m:Node) -> String:
	var n:Node=m
	for i in range(4):
		if n==null:break
		if n.has_meta("prop_asset"):return "prop:"+str(n.get_meta("prop_asset"))
		if n.has_meta("boat"):return "boat"
		n=n.get_parent()
	var mat=m.material_override if m is GeometryInstance3D else null
	var kind=""
	if mat:kind=str(mat.get_meta("surface_kind",mat.resource_name)) if mat.has_meta("surface_kind") or mat.resource_name!="" else mat.get_class()
	if mat is ShaderMaterial and mat.shader:kind+="/"+str(mat.shader.code).get_slice("\n",1).substr(0,12)+" tint="+Color(mat.get_shader_parameter("tint") if mat.get_shader_parameter("tint")!=null else Color.BLACK).to_html(false)
	return "%s<%s>[%s]"%[str(m.get_parent().name),str(m.name),kind]
func run():
	var maps=Array(OS.get_cmdline_user_args()).filter(func(x):return str(x).is_valid_int()).map(func(x):return int(x))
	if maps.is_empty():maps=range(32)
	Catalog.load_all()
	for index in maps:
		var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		# triangles: [n, d, a, b, c, source id, colour, label]
		var buckets={}
		var source=0
		for m in arena.find_children("*","MeshInstance3D",true,false):
			if not m.visible or m.mesh==null or not m.is_visible_in_tree():continue
			var mat=m.material_override
			if mat is StandardMaterial3D and mat.albedo_color.a<.99:continue # translucent (water, glass) is meant to overlap
			if mat is ShaderMaterial and str(mat.shader.code).contains("blend_mix"):continue
			var xf:Transform3D=m.global_transform;var name=label(m)
			var flip=-1. if xf.basis.determinant()<0. else 1. # mirrored: the winding (and so the face normal) turns over
			for s in range(m.mesh.get_surface_count()):
				source+=1
				var arrays=m.mesh.surface_get_arrays(s)
				var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var cols=arrays[Mesh.ARRAY_COLOR];var idx=arrays[Mesh.ARRAY_INDEX]
				var count=idx.size() if idx!=null and idx.size()>0 else v.size()
				for t in range(0,count,3):
					var i0=idx[t] if idx!=null and idx.size()>0 else t;var i1=idx[t+1] if idx!=null and idx.size()>0 else t+1;var i2=idx[t+2] if idx!=null and idx.size()>0 else t+2
					var a=xf*v[i0];var b=xf*v[i1];var c=xf*v[i2]
					var nn=(b-a).cross(c-a)
					if nn.length()<.01:continue # (area under 5 cm2)
					var n=nn.normalized()*flip;var d=n.dot(a)
					var col=Color(cols[i0]) if cols!=null and cols.size()>i0 else Color.WHITE
					var key=Vector4i(roundi(n.x*40.),roundi(n.y*40.),roundi(n.z*40.),roundi(d/SLAB))
					if not buckets.has(key):buckets[key]=[]
					buckets[key].append([n,d,a,b,c,source,col,name])
		var hits=[]
		for key in buckets:
			var list:Array=buckets[key]
			# also the neighbouring slab (d just across a bucket edge)
			var other_key=Vector4i(key.x,key.y,key.z,key.w+1)
			var others:Array=buckets.get(other_key,[])
			var pool=list+others
			if pool.size()<2:continue
			var sources={}
			for t in pool:sources[t[5]]=true
			if sources.size()<2:continue
			var n:Vector3=list[0][0]
			# (Godot's front faces wind clockwise, so n points into the solid: n.y>0 is a
			# face looking down.) Undersides lying on the ground are never seen.
			if n.y>.9 and absf(float(list[0][1]))<.02:continue
			var u=n.cross(Vector3.UP if absf(n.y)<.9 else Vector3.RIGHT).normalized();var w=n.cross(u)
			# 2D cells of 2 m on the plane, to compare only near triangles
			var cells={}
			for i in range(pool.size()):
				var t=pool[i];var lo=Vector2(INF,INF);var hi=-lo
				for p in [t[2],t[3],t[4]]:var q=Vector2(u.dot(p),w.dot(p));lo=lo.min(q);hi=hi.max(q)
				t.append(Rect2(lo,hi-lo))
				for gx in range(floori(lo.x/2.),floori(hi.x/2.)+1):
					for gy in range(floori(lo.y/2.),floori(hi.y/2.)+1):
						var ck=Vector2i(gx,gy)
						if not cells.has(ck):cells[ck]=[]
						cells[ck].append(i)
			var seen={}
			for ck in cells:
				var ids:Array=cells[ck]
				for x in range(ids.size()):
					for y in range(x+1,ids.size()):
						var A=pool[ids[x]];var Bt=pool[ids[y]]
						if A[5]==Bt[5]:continue
						if A[6].is_equal_approx(Bt[6]) and str(A[7]).get_slice("[",1)==str(Bt[7]).get_slice("[",1):continue # same colour, same material: draws identically
						if absf(A[1]-Bt[1])>SLAB:continue
						if n.y>.9 and str(A[7]).begins_with("prop:") and str(Bt[7]).begins_with("prop:"):continue # two props' undersides on a floor
						var pk=str(mini(ids[x],ids[y]))+":"+str(maxi(ids[x],ids[y]))
						if seen.has(pk):continue
						seen[pk]=true
						if not Rect2(A[8]).intersects(Bt[8]):continue
						var pa=PackedVector2Array([Vector2(u.dot(A[2]),w.dot(A[2])),Vector2(u.dot(A[3]),w.dot(A[3])),Vector2(u.dot(A[4]),w.dot(A[4]))])
						var pb=PackedVector2Array([Vector2(u.dot(Bt[2]),w.dot(Bt[2])),Vector2(u.dot(Bt[3]),w.dot(Bt[3])),Vector2(u.dot(Bt[4]),w.dot(Bt[4]))])
						var area=0.
						for poly in Geometry2D.intersect_polygons(pa,pb):
							var s2=0.
							for k in range(poly.size()):s2+=poly[k].cross(poly[(k+1)%poly.size()])
							area+=absf(s2)*.5
						if area>MIN_AREA:hits.append([area,(A[2]+A[3]+A[4])/3.,A[7],Bt[7],A[6],Bt[6],A[0],[A[2],A[3],A[4]],[Bt[2],Bt[3],Bt[4]]])
		hits.sort_custom(func(p,q):return p[0]>q[0])
		var places={}
		for h in hits:
			var k=Vector3i((Vector3(h[1])/2.).round())
			if not places.has(k):places[k]=h
		print("ZFIGHT map %d: %d overlapping face pairs at %d places"%[index,hits.size(),places.size()])
		# by kind of pair (what to fix)
		var kinds={}
		for k in places:
			var h=places[k];var pair=[str(h[2]).get_slice("<",0)+"|"+str(h[2]).get_slice("[",1),str(h[3]).get_slice("<",0)+"|"+str(h[3]).get_slice("[",1)];pair.sort()
			var name=pair[0]+"  ~  "+pair[1]
			kinds[name]=kinds.get(name,0)+1
		for name in kinds:print("   KIND %3d  %s"%[kinds[name],name.substr(0,200)])
		var shown=0
		for k in places:
			var h=places[k];print("   %.2f m2 at %s n=%s  %s / %s  %s %s"%[h[0],str(Vector3(h[1]).snapped(Vector3.ONE*.1)),str(Vector3(h[6]).snapped(Vector3.ONE*.01)),h[2],h[3],Color(h[4]).to_html(false),Color(h[5]).to_html(false)])
			if OS.get_cmdline_user_args().has("--tris"):print("      A ",h[7],"\n      B ",h[8])
			shown+=1
			if shown>=12 and not OS.get_cmdline_user_args().has("--all"):break
		found+=places.size()
		arena.queue_free()
		for i in range(3):await process_frame
	print("ZFIGHT_TOTAL ",found)
	quit()
