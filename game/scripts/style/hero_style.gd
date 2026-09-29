class_name HeroStyle
extends RefCounted
## Cartoon art direction (Overwatch/Splatoon inspired): saturated team colours,
## rounded chunky forms, painted faces and cel shading. All parts are built from
## cached primitives and merged per joint, so one hero costs ~15 small draws.
const TEAM_MAIN=[Color("3f86ee"),Color("ff8a2e")]
const TEAM_LIGHT=[Color("9cd0ff"),Color("ffd08a")]
const TEAM_DEEP=[Color("24407a"),Color("8a3c14")]
const SUIT=Color("2e3547")
const SUIT_MID=Color("4a5468")
const WHITE=Color("f2f4f7")
const INK=Color("1d2230")
const ROLE_ACCENT=[Color("ffd24a"),Color("8fe060"),Color("ef5a4f"),Color("ffb000"),Color("a47cff"),Color("4fe3c1")]
const HAIR=[Color("3a2a22"),Color("6b3f2a"),Color("2b2b33"),Color("8a5a2b"),Color("1f1d26"),Color("d98bb0")]
const SKIN=[Color("f0c9a4"),Color("f7d8bd"),Color("b98256"),Color("e8b98d"),Color("c99670"),Color("f6d6c3")]
static var toon:Shader
static var outline:Shader
static var materials={}
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
	var n=MeshFactory.sphere(parent,pos,size,color);n.rotation=rot;return n
static func rbox(parent:Node,pos:Vector3,size:Vector3,color:Color,rot=Vector3.ZERO,round=.55) -> MeshInstance3D:
	return MeshFactory.box(parent,pos,size,color,rot,round)
static func cyl(parent:Node,pos:Vector3,radius:float,height:float,color:Color,rot=Vector3.ZERO,top=-1.) -> MeshInstance3D:
	return MeshFactory.cylinder(parent,pos,radius,height,color,rot,top,12)
# Merges every joint's primitives and assigns the cel material (recursively).
static func finish(root:Node3D,outlined:bool=false,gloss:float=0.):
	MeshFactory.merge_rig(root)
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		# A lone primitive on a joint is not merged and has no vertex colours.
		var solo=mesh.material_override is StandardMaterial3D
		mesh.material_override=tinted(mesh.material_override.albedo_color,outlined,gloss) if solo else toon_material(outlined,gloss)
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
static func tinted(color:Color,outlined:bool,gloss:float) -> ShaderMaterial:
	var key=str([color,outlined,gloss])
	if materials.has(key):return materials[key]
	var m=toon_material(outlined,gloss).duplicate();m.set_shader_parameter("tint",color);m.set_shader_parameter("vertex_color",0.)
	materials[key]=m;return m
