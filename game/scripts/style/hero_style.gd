class_name HeroStyle
extends RefCounted
## Cartoon art direction (Overwatch/Splatoon inspired): saturated team colours,
## rounded chunky forms, painted faces and cel shading. All parts are built from
## cached primitives and merged per joint, so one hero costs ~15 small draws.
const TEAM_MAIN=[Color("3574d0"),Color("e2772a")]
const TEAM_LIGHT=[Color("86b8ea"),Color("f0b877")]
const TEAM_DEEP=[Color("22407a"),Color("7e3814")]
const SUIT=Color("2b3142")
const SUIT_MID=Color("485164")
const METAL=Color("8a93a3")
const WHITE=Color("dfe3ea")
const INK=Color("1b202c")
const STRAP=Color("3c3530")
# Per-role outfit base: team colour lives on armour and trim, so roles differ
# at a glance while teams stay readable.
const ROLE_SUIT=[Color("4a5566"),Color("5b6b47"),Color("3a4150"),Color("6e573f"),Color("4f4574"),Color("d9dde4")]
const ROLE_ACCENT=[Color("f2c03e"),Color("7fce52"),Color("de4d44"),Color("f0a000"),Color("9270e8"),Color("3fcfae")]
const HAIR=[Color("3a2a22"),Color("6b3f2a"),Color("2b2b33"),Color("8a5a2b"),Color("1f1d26"),Color("c77ca0")]
const SKIN=[Color("e8bf98"),Color("f0cfb2"),Color("a8744b"),Color("dcaf84"),Color("bb8a64"),Color("efcdb9")]
static var sphere_mesh:SphereMesh
static var toon:Shader
static var outline:Shader
static var materials={}
# Ink outlines double the vertex work, so only the high native preset gets them.
static func outlines_enabled() -> bool:
	return not RenderStyle.web() and GraphicsOptions.detail>=2
static func toon_material(outlined:bool=false,gloss:float=0.) -> ShaderMaterial:
	var key=str([outlined,gloss])
	if materials.has(key):return materials[key]
	if toon==null:toon=load("res://shaders/hero_toon.gdshader");outline=load("res://shaders/hero_outline.gdshader")
	var m=ShaderMaterial.new();m.shader=toon;m.set_shader_parameter("gloss",gloss)
	if outlined:
		var ink=ShaderMaterial.new();ink.shader=outline;m.next_pass=ink
	materials[key]=m;return m
# Rounded primitives. Colours become vertex colours when merged.
static func ell(parent:Node,pos:Vector3,size:Vector3,color:Color,rot=Vector3.ZERO) -> MeshInstance3D:
	# 14x7 sphere (~170 triangles): smooth under cel shading, cheap on iGPUs.
	if sphere_mesh==null:sphere_mesh=SphereMesh.new();sphere_mesh.radius=.5;sphere_mesh.height=1.;sphere_mesh.radial_segments=14;sphere_mesh.rings=7
	var n=MeshFactory.instance(parent,sphere_mesh,pos,color,rot);n.scale=size;return n
# Thin strap/panel strip following a direction.
static func strip(parent:Node,a:Vector3,b:Vector3,width:float,depth:float,color:Color) -> MeshInstance3D:
	var mid=(a+b)*.5;var length=a.distance_to(b)
	var n=rbox(parent,mid,Vector3(width,length,depth),color,Vector3.ZERO,.5)
	var up=(b-a).normalized();var side=up.cross(Vector3.FORWARD)
	if side.length()<.01:side=Vector3.RIGHT
	n.basis=Basis(side.normalized(),up,side.normalized().cross(up))
	return n
static func rbox(parent:Node,pos:Vector3,size:Vector3,color:Color,rot=Vector3.ZERO,round=.55) -> MeshInstance3D:
	return MeshFactory.box(parent,pos,size,color,rot,round)
static func cyl(parent:Node,pos:Vector3,radius:float,height:float,color:Color,rot=Vector3.ZERO,top=-1.) -> MeshInstance3D:
	return MeshFactory.cylinder(parent,pos,radius,height,color,rot,top,12)
# Merges every joint's primitives and assigns the cel material (recursively).
static func finish(root:Node3D,outlined:bool=false,gloss:float=0.):
	MeshFactory.merge_rig(root)
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if outlined:mesh.mesh=with_smooth_normals(mesh.mesh)
		# A lone primitive on a joint is not merged and has no vertex colours.
		var solo=mesh.material_override is StandardMaterial3D
		mesh.material_override=tinted(mesh.material_override.albedo_color,outlined,gloss) if solo else toon_material(outlined,gloss)
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
# Welds coincident vertices and stores the averaged normal in TANGENT for the
# outline pass; shading keeps the original (hard) normals.
static var smoothed={}
static func with_smooth_normals(source:Mesh) -> Mesh:
	if source==null or source.get_surface_count()==0:return source
	if smoothed.has(source):return smoothed[source]
	var out=ArrayMesh.new()
	for surface in range(source.get_surface_count()):
		var arrays=source.surface_get_arrays(surface)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var sums={}
		for i in range(vertices.size()):
			var key=vertices[i].snapped(Vector3.ONE*.0005)
			sums[key]=sums.get(key,Vector3.ZERO)+normals[i]
		var tangents=PackedFloat32Array();tangents.resize(vertices.size()*4)
		for i in range(vertices.size()):
			var n:Vector3=sums[vertices[i].snapped(Vector3.ONE*.0005)].normalized()
			tangents[i*4]=n.x;tangents[i*4+1]=n.y;tangents[i*4+2]=n.z;tangents[i*4+3]=1.
		arrays[Mesh.ARRAY_TANGENT]=tangents
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		out.surface_set_material(surface,source.surface_get_material(surface))
	MeshFactory.bound_cache(smoothed,512);smoothed[source]=out
	return out
static func tinted(color:Color,outlined:bool,gloss:float) -> ShaderMaterial:
	var key=str([color,outlined,gloss])
	if materials.has(key):return materials[key]
	var m=toon_material(outlined,gloss).duplicate();m.set_shader_parameter("tint",color);m.set_shader_parameter("vertex_color",0.)
	materials[key]=m;return m
# Same cel material drawn from both sides (open meshes: baked magazines).
static var double_shader:Shader
static func double_sided(source:Material) -> Material:
	if not source is ShaderMaterial:return source
	var key="double"+str(source.get_instance_id())
	if materials.has(key):return materials[key]
	if double_shader==null:double_shader=load("res://shaders/hero_toon_double.gdshader")
	var m:ShaderMaterial=source.duplicate();m.shader=double_shader;m.next_pass=null
	materials[key]=m;return m
# Releases every cached shader/material/mesh (tests and shutdown).
static func clear_cache():
	materials.clear();smoothed.clear();toon=null;outline=null;sphere_mesh=null;double_shader=null
	GunModel.bases.clear();GadgetVisual.templates.clear();CombatFX.device_templates.clear()
	HeroCharacter.scenes.clear();HeroCharacter.libraries.clear();HeroCharacter.bodies.clear()
