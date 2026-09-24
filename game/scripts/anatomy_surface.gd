extends RefCounted
class_name AnatomySurface
# Smooth implicit clothing volumes. One continuous shoulder/torso surface and
# one pelvis/leg surface remove rigid-part seams before skin weights are applied.
static var meshes={}
const STEP=.022
const CORNERS=[Vector3i(0,0,0),Vector3i(1,0,0),Vector3i(1,1,0),Vector3i(0,1,0),Vector3i(0,0,1),Vector3i(1,0,1),Vector3i(1,1,1),Vector3i(0,1,1)]
const TETS=[[0,5,1,6],[0,1,2,6],[0,2,3,6],[0,3,7,6],[0,7,4,6],[0,4,5,6]]
const EDGES=[[0,1],[0,2],[0,3],[1,2],[1,3],[2,3]]
static func ellipsoid(p:Vector3,center:Vector3,radius:Vector3) -> float:
	var q=p-center;var k0=(q/radius).length();var k1=(q/(radius*radius)).length()
	return -minf(radius.x,minf(radius.y,radius.z)) if k1<.001 else k0*(k0-1.)/k1
static func capsule(p:Vector3,a:Vector3,b:Vector3,ra:float,rb:float) -> float:
	var axis=b-a;var t=clampf((p-a).dot(axis)/axis.length_squared(),0.,1.);return p.distance_to(a+axis*t)-lerpf(ra,rb,t)
static func blend(a:float,b:float,k:float) -> float:
	var h=clampf(.5+.5*(b-a)/k,0.,1.);return lerpf(b,a,h)-k*h*(1.-h)
static func field(p:Vector3,kind:int) -> float:
	if kind==0:
		var d=ellipsoid(p,Vector3(0,1.245,.005),Vector3(.187,.226,.125))
		d=blend(d,ellipsoid(p,Vector3(0,1.087,0),Vector3(.146,.13,.106)),.045)
		d=blend(d,ellipsoid(p,Vector3(0,1.43,0),Vector3(.073,.069,.062)),.032)
		for side in [-1,1]:
			d=blend(d,ellipsoid(p,Vector3(side*.161,1.38,0),Vector3(.075,.081,.098)),.026)
			d=blend(d,capsule(p,Vector3(side*.211,1.365,0),Vector3(side*.211,1.135,0),.064,.054),.024)
		return d
	var d=ellipsoid(p,Vector3(0,.933,.007),Vector3(.164,.124,.125))
	for side in [-1,1]:
		d=blend(d,capsule(p,Vector3(side*.099,.897,.002),Vector3(side*.099,.506,0),.089,.060),.020)
		d=blend(d,ellipsoid(p,Vector3(side*.099,.305,.018),Vector3(.064,.191,.069)),.018)
		d=blend(d,capsule(p,Vector3(side*.099,.32,.015),Vector3(side*.099,.09,.018),.058,.040),.015)
	return d
static func normal(p:Vector3,kind:int) -> Vector3:
	var e=.002
	return Vector3(field(p+Vector3(e,0,0),kind)-field(p-Vector3(e,0,0),kind),field(p+Vector3(0,e,0),kind)-field(p-Vector3(0,e,0),kind),field(p+Vector3(0,0,e),kind)-field(p-Vector3(0,0,e),kind)).normalized()
static func mesh(kind:int) -> ArrayMesh:
	if meshes.has(kind):return meshes[kind]
	var start=Vector3(-.31,.94 if kind==0 else .025,-.18)
	var dimensions=Vector3i(29,27 if kind==0 else 48,18)
	var samples=PackedFloat32Array();samples.resize(dimensions.x*dimensions.y*dimensions.z)
	for z in range(dimensions.z):
		for y in range(dimensions.y):
			for x in range(dimensions.x):samples[x+dimensions.x*(y+dimensions.y*z)]=field(start+Vector3(x,y,z)*STEP,kind)
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(dimensions.z-1):
		for y in range(dimensions.y-1):
			for x in range(dimensions.x-1):
				var positions=[];var values=[];var inside=0
				for corner in CORNERS:
					var q=Vector3i(x,y,z)+corner;var value=samples[q.x+dimensions.x*(q.y+dimensions.y*q.z)]
					positions.append(start+Vector3(q)*STEP);values.append(value)
					if value<0:inside+=1
				if inside==0 or inside==8:continue
				for tetra in TETS:
					var polygon=[]
					for edge in EDGES:
						var a=tetra[edge[0]];var b=tetra[edge[1]]
						if (values[a]<0)!=(values[b]<0):polygon.append(positions[a].lerp(positions[b],values[a]/(values[a]-values[b])))
					if polygon.size()<3:continue
					var center=Vector3.ZERO
					for point in polygon:center+=point
					center/=polygon.size();var n=normal(center,kind);var axis=(polygon[0]-center).normalized();var second=n.cross(axis)
					polygon.sort_custom(func(a,b):return atan2((a-center).dot(second),(a-center).dot(axis))<atan2((b-center).dot(second),(b-center).dot(axis)))
					for i in range(1,polygon.size()-1):
						for point in [polygon[0],polygon[i+1],polygon[i]]:st.set_normal(normal(point,kind));st.add_vertex(point-Vector3.UP*.94)
	st.index();meshes[kind]=st.commit();return meshes[kind]
static func replace(root:Node3D,shirt:Color,trousers:Color):
	_remove_base(root,shirt,trousers)
	for kind in range(2):
		var node=MeshFactory.instance(root.get_node("Hips"),mesh(kind),Vector3.ZERO,shirt if kind==0 else trousers)
		node.name="SculptedShirt" if kind==0 else "SculptedTrousers";node.set_meta("deform_shell",kind)
static func _remove_base(node:Node3D,shirt:Color,trousers:Color):
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			if child.material_override.albedo_color==shirt or child.material_override.albedo_color==trousers:node.remove_child(child);child.free()
		elif child is Node3D:_remove_base(child,shirt,trousers)
