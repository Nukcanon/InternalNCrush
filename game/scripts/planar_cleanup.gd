class_name PlanarCleanup
extends RefCounted
## Clip coplanar triangles across all opaque meshes, including rotated/beveled ones.
## Collision solids are untouched. Texture coordinates/normals are interpolated.
const EPS=.000002
static func area(p:Array) -> float:
	var value=0.
	for i in range(p.size()):value+=p[i].cross(p[(i+1)%p.size()])
	return value*.5
static func half(poly:Array,a:Vector2,b:Vector2,inside:bool) -> Array:
	if poly.is_empty():return []
	var result=[];var previous:Vector2=poly[-1];var edge=b-a
	var before=edge.cross(previous-a)*(1. if inside else -1.)
	for point in poly:
		var after=edge.cross(point-a)*(1. if inside else -1.)
		if (before>=0.)!=(after>=0.):result.append(previous.lerp(point,clampf(before/(before-after),0.,1.)))
		if after>=0.:result.append(point)
		previous=point;before=after
	return result
static func subtract(subject:Array,clip:Array) -> Array:
	var remaining=subject;var pieces=[];var boundary=clip.duplicate()
	if area(boundary)<0.:boundary.reverse()
	for i in range(boundary.size()):
		var outside=half(remaining,boundary[i],boundary[(i+1)%boundary.size()],false)
		if outside.size()>=3 and absf(area(outside))>EPS:pieces.append(outside)
		remaining=half(remaining,boundary[i],boundary[(i+1)%boundary.size()],true)
		if remaining.size()<3:break
	return pieces
static func rect(points:Array) -> Rect2:
	var result=Rect2(points[0],Vector2.ZERO)
	for point in points:result=result.expand(point)
	return result
static func clean(root:Node3D) -> int:
	var planes={};var surfaces=[];var removed=0
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if not mesh.visible or mesh.mesh==null or mesh.mesh.get_surface_count()!=1:continue
		for surface in range(mesh.mesh.get_surface_count()):
			var material=mesh.material_override if mesh.material_override else mesh.mesh.surface_get_material(surface)
			if not material is StandardMaterial3D or material.albedo_color.a<1.:continue
			var arrays=mesh.mesh.surface_get_arrays(surface);var v=arrays[Mesh.ARRAY_VERTEX];var indices=arrays[Mesh.ARRAY_INDEX]
			var record={"mesh":mesh,"material":material,"arrays":arrays,"faces":[],"changed":false};surfaces.append(record)
			var count=indices.size() if indices!=null and not indices.is_empty() else v.size()
			for offset in range(0,count,3):
				var ids=[];var points=[]
				for i in range(3):
					var id=indices[offset+i] if indices!=null and not indices.is_empty() else offset+i
					ids.append(id);points.append(mesh.global_transform*v[id])
				var normal:Vector3=(points[1]-points[0]).cross(points[2]-points[0]).normalized()
				if normal.length_squared()<.1:continue
				var axis=0 if absf(normal.x)>absf(normal.y) and absf(normal.x)>absf(normal.z) else 1 if absf(normal.y)>absf(normal.z) else 2
				var sign_n=signf(normal[axis]);var canonical=normal*sign_n;var u=(axis+1)%3;var w=(axis+2)%3
				var projected=[]
				for point in points:projected.append(Vector2(point[u],point[w]))
				var key=str(Vector3i((canonical*10000.).round()))+":"+str(roundi(canonical.dot(points[0])*10000.))
				if not planes.has(key):planes[key]={"faces":[],"cells":{}}
				var group=planes[key];var bounds=rect(projected)
				var face={"ids":ids,"poly":projected,"rect":bounds,"sign":sign_n,"owner":surfaces.size()-1,"mesh":mesh,"index":group.faces.size(),"pieces":[projected]}
				group.faces.append(face);record.faces.append(face)
				for x in range(floori(bounds.position.x/8.),floori(bounds.end.x/8.)+1):
					for y in range(floori(bounds.position.y/8.),floori(bounds.end.y/8.)+1):
						var cell=Vector2i(x,y)
						if not group.cells.has(cell):group.cells[cell]=[]
						group.cells[cell].append(face.index)
	for group in planes.values():
		if group.faces.size()<2:continue
		for face in group.faces:
			var candidates={};var bounds:Rect2=face.rect
			for x in range(floori(bounds.position.x/8.),floori(bounds.end.x/8.)+1):
				for y in range(floori(bounds.position.y/8.),floori(bounds.end.y/8.)+1):
					for id in group.cells[Vector2i(x,y)]:candidates[id]=true
			for id in candidates:
				var other=group.faces[id]
				if face.mesh==other.mesh or (id>face.index and face.sign==other.sign) or not face.rect.intersects(other.rect):continue
				var overlap=Geometry2D.intersect_polygons(PackedVector2Array(face.poly),PackedVector2Array(other.poly))
				if overlap.is_empty() or absf(area(Array(overlap[0])))<EPS:continue
				var pieces=[]
				for polygon in face.pieces:pieces.append_array(subtract(polygon,other.poly))
				face.pieces=pieces;surfaces[face.owner].changed=true;removed+=1
	for record in surfaces:
		if not record.changed:continue
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var count=0
		for face in record.faces:
			for polygon in face.pieces:
				for i in range(1,polygon.size()-1):
					for p in [polygon[0],polygon[i],polygon[i+1]]:
						var triangle=face.poly;var den=(triangle[1]-triangle[0]).cross(triangle[2]-triangle[0])
						if absf(den)<EPS:continue
						var b=(p-triangle[0]).cross(triangle[2]-triangle[0])/den;var c=(triangle[1]-triangle[0]).cross(p-triangle[0])/den;var weights=[1.-b-c,b,c]
						var pos=Vector3.ZERO;var normal=Vector3.ZERO;var uv=Vector2.ZERO
						for k in range(3):
							var id=face.ids[k];pos+=record.arrays[Mesh.ARRAY_VERTEX][id]*weights[k];normal+=record.arrays[Mesh.ARRAY_NORMAL][id]*weights[k]
							if record.arrays[Mesh.ARRAY_TEX_UV]!=null:uv+=record.arrays[Mesh.ARRAY_TEX_UV][id]*weights[k]
						st.set_normal(normal.normalized());st.set_uv(uv);st.add_vertex(pos);count+=1
		if count>0:record.mesh.mesh=st.commit()
		else:record.mesh.visible=false;record.mesh.mesh=ArrayMesh.new()
	root.set_meta("planar_overlaps_removed",removed);return removed
