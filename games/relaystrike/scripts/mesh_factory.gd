extends RefCounted
class_name MeshFactory
static var materials={}
static var meshes={}
static var vertex_material:StandardMaterial3D
static func material(color:Color) -> StandardMaterial3D:
	if materials.has(color):return materials[color]
	var m=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.82
	if color.a<1:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;m.cull_mode=BaseMaterial3D.CULL_DISABLED
	materials[color]=m;return m
static func instance(parent:Node,mesh:Mesh,pos:Vector3,color:Color,rot=Vector3.ZERO) -> MeshInstance3D:
	var node=MeshInstance3D.new();node.mesh=mesh;node.position=pos;node.rotation=rot;node.material_override=material(color);parent.add_child(node);return node
static func box(parent:Node,pos:Vector3,size:Vector3,color:Color,rot=Vector3.ZERO,bevel=.3) -> MeshInstance3D:
	var key=str(size)+str(bevel)
	if not meshes.has(key):meshes[key]=beveled_box(size,bevel)
	return instance(parent,meshes[key],pos,color,rot)
static func cylinder(parent:Node,pos:Vector3,radius:float,height:float,color:Color,rot=Vector3.ZERO,top=-1.,sides=10) -> MeshInstance3D:
	var key="c"+str([radius,height,top,sides])
	if not meshes.has(key):
		var m=CylinderMesh.new();m.top_radius=radius if top<0 else top;m.bottom_radius=radius;m.height=height;m.radial_segments=sides;meshes[key]=m
	return instance(parent,meshes[key],pos,color,rot)
static func sphere(parent:Node,pos:Vector3,size:Vector3,color:Color) -> MeshInstance3D:
	if not meshes.has("sphere"):
		var m=SphereMesh.new();m.radius=.5;m.height=1.;m.radial_segments=12;m.rings=6;meshes.sphere=m
	var n=instance(parent,meshes.sphere,pos,color);n.scale=size;return n
static func tapered(parent:Node,pos:Vector3,size:Vector3,color:Color,ratio=.75) -> MeshInstance3D:
	var mesh=beveled_box(size,.25)
	var arrays=mesh.surface_get_arrays(0);var vertices=arrays[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()):
		var factor=lerpf(ratio,1.,clampf(vertices[i].y/size.y+.5,0,1));vertices[i].x*=factor;vertices[i].z*=factor
	arrays[Mesh.ARRAY_VERTEX]=vertices
	var out=ArrayMesh.new();out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return instance(parent,out,pos,color)
static func beveled_box(size:Vector3,amount=.16) -> ArrayMesh:
	var x=size.x*.5;var y=size.y*.5;var z=size.z*.5;var c=minf(minf(x,y),z)*clampf(amount,.02,.85)
	var ring=[Vector2(-x+c,-y),Vector2(x-c,-y),Vector2(x,-y+c),Vector2(x,y-c),Vector2(x-c,y),Vector2(-x+c,y),Vector2(-x,y-c),Vector2(-x,-y+c)]
	var rings=[]
	for layer in range(4):
		var points=[];var inset=c*.55 if layer in [0,3] else 0.;var zz=[-z,-z+c,z-c,z][layer]
		for v in ring:points.append(Vector3(v.x-sign(v.x)*inset,v.y-sign(v.y)*inset,zz))
		rings.append(points)
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(3):
		for i in range(8):
			var j=(i+1)%8;var points=[rings[layer][i],rings[layer+1][i],rings[layer][j],rings[layer][j],rings[layer+1][i],rings[layer+1][j]]
			for tri in range(2):
				var n=(points[tri*3+2]-points[tri*3]).cross(points[tri*3+1]-points[tri*3]).normalized()
				for k in range(3):st.set_normal(n);st.add_vertex(points[tri*3+k])
	for i in range(8):
		var j=(i+1)%8
		for point in [Vector3(0,0,-z),rings[0][i],rings[0][j]]:st.set_normal(Vector3.FORWARD);st.add_vertex(point)
		for point in [Vector3(0,0,z),rings[3][j],rings[3][i]]:st.set_normal(Vector3.BACK);st.add_vertex(point)
	return st.commit()
static func merge_children(parent:Node3D):
	var children=[]
	for child in parent.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D and child.material_override.albedo_color.a>=1:children.append(child)
	if children.size()<2:return
	if vertex_material==null:
		vertex_material=StandardMaterial3D.new();vertex_material.vertex_color_use_as_albedo=true;vertex_material.vertex_color_is_srgb=false;vertex_material.roughness=.84
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for child in children:
		var arrays=child.mesh.surface_get_arrays(0);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var indices=arrays[Mesh.ARRAY_INDEX]
		var count=indices.size() if indices!=null and indices.size()>0 else vertices.size()
		for j in range(count):
			var i=indices[j] if indices!=null and indices.size()>0 else j
			st.set_color(child.material_override.albedo_color.srgb_to_linear());st.set_normal((child.transform.basis.inverse().transposed()*normals[i]).normalized());st.add_vertex(child.transform*vertices[i])
		parent.remove_child(child);child.free()
	st.set_material(vertex_material);var node=MeshInstance3D.new();node.name="Geometry";node.mesh=st.commit();parent.add_child(node)
static func merge_rig(parent:Node3D):
	for child in parent.get_children():
		if child is Node3D and not child is MeshInstance3D:merge_rig(child)
	merge_children(parent)
static func own_recursive(node:Node,owner:Node):
	for child in node.get_children():child.owner=owner;own_recursive(child,owner)
