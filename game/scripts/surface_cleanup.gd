extends RefCounted
class_name SurfaceCleanup
# Clip overlapping coplanar box faces before batching. Collision solids remain intact.
static func subtract_rect(a:Rect2,b:Rect2) -> Array:
	var cut=a.intersection(b)
	if not cut.has_area():return [a]
	var out=[]
	for r in [Rect2(a.position,Vector2(cut.position.x-a.position.x,a.size.y)),Rect2(Vector2(cut.end.x,a.position.y),Vector2(a.end.x-cut.end.x,a.size.y)),Rect2(Vector2(cut.position.x,a.position.y),Vector2(cut.size.x,cut.position.y-a.position.y)),Rect2(Vector2(cut.position.x,cut.end.y),Vector2(cut.size.x,a.end.y-cut.end.y))]:
		if r.size.x>.00001 and r.size.y>.00001:out.append(r)
	return out
static func clean(root:Node3D) -> int:
	var meshes=root.find_children("*","MeshInstance3D",true,false);var planes={};var records={};var removed=0
	for mesh in meshes:
		if not mesh.mesh is BoxMesh or not mesh.material_override is StandardMaterial3D or mesh.material_override.albedo_color.a<1.:continue
		var basis:Basis=mesh.global_basis
		if not basis.is_equal_approx(Basis.IDENTITY):continue
		var box=mesh.global_transform*mesh.get_aabb();records[mesh]=[]
		for axis in range(3):
			var u=(axis+1)%3;var v=(axis+2)%3
			for side in [-1,1]:
				var height=box.position[axis] if side<0 else box.end[axis]
				var key=str(axis)+"/"+str(roundi(height*10000.))
				if not planes.has(key):planes[key]=[]
				planes[key].append({"mesh":mesh,"axis":axis,"side":side,"height":height,"rect":Rect2(Vector2(box.position[u],box.position[v]),Vector2(box.size[u],box.size[v]))})
	for faces in planes.values():
		for i in range(faces.size()):
			var face=faces[i];var pieces=[face.rect]
			for j in range(faces.size()):
				if i==j or (j>i and face.side==faces[j].side):continue
				var next=[]
				for piece in pieces:next.append_array(subtract_rect(piece,faces[j].rect))
				pieces=next
			if pieces.is_empty():removed+=1
			for rect in pieces:
				var copy=face.duplicate();copy.rect=rect;records[face.mesh].append(copy)
	for mesh in records:
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var count=0
		for face in records[mesh]:
			var rect:Rect2=face.rect;var points=[];var normal=Vector3.ZERO;normal[face.axis]=face.side
			for corner in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
				var point=Vector3.ZERO;point[face.axis]=face.height;point[(face.axis+1)%3]=corner.x;point[(face.axis+2)%3]=corner.y;points.append(point)
			for k in ([0,2,1,0,3,2] if face.side>0 else [0,1,2,0,2,3]):st.set_normal(normal);st.add_vertex(points[k]);count+=1
		if count==0:mesh.visible=false;mesh.mesh=ArrayMesh.new()
		else:mesh.mesh=st.commit();mesh.global_transform=Transform3D.IDENTITY
	root.set_meta("coplanar_faces_removed",removed);return removed
