extends RefCounted
class_name HumanModel
## 1.4: geometry helpers only (lofted volumes for trees, props, projectiles).
## Heroes are HeroCharacter; the procedural operator models were removed.
const M=preload("res://scripts/mesh_factory.gd")
const HEIGHTS=[1.74,1.64,1.88,1.72,1.83,1.62]
const WIDTHS=[1.0,.88,1.08,1.01,.98,.88]
const FEMALE_ROLES=[1,5]
const IDENTITIES=["MASON", "SERA", "BRIGGS", "REED", "VALE", "MINA"]
const SKIN_COLORS=[Color("b3a28c"),Color("cbbcaf"),Color("89765f"),Color("b9a48a"),Color("9b866e"),Color("c7b6a8")]
static var loft_meshes={}
const LOFT_CACHE_LIMIT=128
static func loft(parent:Node,pos:Vector3,rings:Array,color:Color,sides:int=20,sculpt:bool=false) -> MeshInstance3D:
	var cache_key=str([rings,sides,sculpt])
	if loft_meshes.has(cache_key):return M.instance(parent,loft_meshes[cache_key],pos,color)
	var smooth=[]
	for j in range(rings.size()-1):
		var a:Vector4=rings[maxi(0,j-1)];var b:Vector4=rings[j];var c:Vector4=rings[j+1];var d:Vector4=rings[mini(rings.size()-1,j+2)]
		for step in range(3):
			var t=step/3.;var point=(b*2.+(c-a)*t+(a*2.-b*5.+c*4.-d)*t*t+(-a+b*3.-c*3.+d)*t*t*t)*.5
			point.y=maxf(.001,point.y);point.z=maxf(.001,point.z);smooth.append(point)
	smooth.append(rings[-1]);rings=smooth
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
	for j in range(rings.size()-1):
		for i in range(sides):
			var a=TAU*i/sides;var b=TAU*(i+1)/sides
			var r=rings[j];var s=rings[j+1]
			var p=Vector3(cos(a)*r.y,r.x,sin(a)*r.z+r.w)
			var q=Vector3(cos(b)*r.y,r.x,sin(b)*r.z+r.w)
			var u=Vector3(cos(a)*s.y,s.x,sin(a)*s.z+s.w)
			var v=Vector3(cos(b)*s.y,s.x,sin(b)*s.z+s.w)
			for point in [p,q,u,q,v,u]:st.add_vertex(sculpt_face(point) if sculpt else point)
	# Every loft is a closed solid, including the stock/receiver seen from behind.
	# Separate smoothing groups keep end caps from rounding side normals.
	st.set_smooth_group(-1)
	for end in [0,rings.size()-1]:
		var r=rings[end];var center=Vector3(0,r.x,r.w)
		for i in range(sides):
			var a=TAU*i/sides;var b=TAU*(i+1)/sides
			var p=Vector3(cos(a)*r.y,r.x,sin(a)*r.z+r.w);var q=Vector3(cos(b)*r.y,r.x,sin(b)*r.z+r.w)
			for point in ([center,q,p] if end==0 else [center,p,q]):st.add_vertex(point)
	st.generate_normals();st.index();var mesh=st.commit()
	MeshFactory.bound_cache(loft_meshes,LOFT_CACHE_LIMIT);loft_meshes[cache_key]=mesh
	return M.instance(parent,mesh,pos,color)
static func sculpt_face(point:Vector3) -> Vector3:
	if point.z>=0:return point
	var x=point.x;var y=point.y;var front=smoothstep(.015,.065,-point.z)
	var eye=exp(-pow((absf(x)-.043)/.024,2)-pow((y-.037)/.018,2))
	var brow=exp(-pow((absf(x)-.038)/.035,2)-pow((y-.064)/.015,2))
	var cheek=exp(-pow((absf(x)-.057)/.027,2)-pow((y+.010)/.025,2))
	var bridge=exp(-pow(x/.012,2)-pow((y-.025)/.035,2))
	var tip=exp(-pow(x/.019,2)-pow((y+.008)/.016,2))
	point.z+=front*(eye*.009-brow*.006-cheek*.006-bridge*.013-tip*.017)
	return point
static func oval(parent:Node,pos:Vector3,size:Vector3,color:Color) -> MeshInstance3D:
	var mesh=SphereMesh.new();mesh.radius=.5;mesh.height=1.;mesh.radial_segments=20;mesh.rings=12
	var n=M.instance(parent,mesh,pos,color);n.scale=size;return n
static func cord(parent:Node,a:Vector3,b:Vector3,radius:float,color:Color):
	var mesh=CapsuleMesh.new();mesh.radius=radius;mesh.height=a.distance_to(b)+radius*2.;mesh.radial_segments=12;mesh.rings=4
	var n=M.instance(parent,mesh,(a+b)*.5,color);n.quaternion=Quaternion(Vector3.UP,(b-a).normalized());return n