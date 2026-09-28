extends RefCounted
class_name ScopeVisual
## Original low-poly optical assembly. Both lenses sit behind protective rims.
static var glass:ShaderMaterial
static func lens(parent:Node3D,z:float,radius:float,label:String):
	var mesh=MeshFactory.cylinder(parent,Vector3(0,0,z),radius,.002,Color("24586f"),Vector3(PI/2,0,0),-1.,24)
	mesh.name=label;mesh.set_meta("scope_lens",true)
	if glass==null:
		glass=ShaderMaterial.new();var shader=Shader.new()
		shader.code="""shader_type spatial;
render_mode cull_disabled;
varying vec2 lens_pos;
void vertex(){lens_pos=VERTEX.xz;}
void fragment(){
 float facing=abs(dot(normalize(NORMAL),normalize(VIEW)));
 float coating=pow(1.-facing,2.);
 float glint=exp(-pow((lens_pos.x+lens_pos.y-.012)*160.,2.));
 vec3 blue=mix(vec3(.018,.065,.11),vec3(.08,.32,.46),.25+coating*.7);
 ALBEDO=blue+vec3(.12,.23,.26)*glint;
 EMISSION=blue*.18;ROUGHNESS=.16;METALLIC=.35;SPECULAR=.7;
}
"""
		glass.shader=shader
	mesh.material_override=glass;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
static func build(parent:Node3D,compact:bool):
	var scope=Node3D.new();scope.name="Scope";scope.position=Vector3(0,.16,-.22);parent.add_child(scope)
	var scale_z=.78 if compact else 1.
	var profile=[Vector2(.036,.135),Vector2(.036,.16),Vector2(.049,.16),Vector2(.049,.105),Vector2(.031,.073),Vector2(.031,-.06),Vector2(.058,-.125),Vector2(.058,-.19),Vector2(.048,-.19),Vector2(.048,-.165)]
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides=20 if RenderStyle.web() else 28
	for j in range(profile.size()-1):
		var a=profile[j];var b=profile[j+1];a.y*=scale_z;b.y*=scale_z
		for i in range(sides):
			var u=Vector2.from_angle(i*TAU/sides);var v=Vector2.from_angle((i+1)*TAU/sides)
			var points=[Vector3(u.x*a.x,u.y*a.x,a.y),Vector3(v.x*a.x,v.y*a.x,a.y),Vector3(u.x*b.x,u.y*b.x,b.y),Vector3(v.x*a.x,v.y*a.x,a.y),Vector3(v.x*b.x,v.y*b.x,b.y),Vector3(u.x*b.x,u.y*b.x,b.y)]
			for point in points:
				var radial=Vector2(point.x,point.y).normalized()
				surface.set_normal(Vector3(radial.x*(a.y-b.y),radial.y*(a.y-b.y),b.x-a.x).normalized());surface.add_vertex(point)
	surface.index();var body=MeshFactory.instance(scope,surface.commit(),Vector3.ZERO,Color("26323b"));body.name="Housing"
	# Mount rings, a ribbed ocular grip and capped adjustment turrets.
	for z in [-.052,.06]:
		MeshFactory.cylinder(scope,Vector3(0,0,z*scale_z),.037,.018,Color("45515a"),Vector3(PI/2,0,0),-1.,sides)
		MeshFactory.box(scope,Vector3(0,-.057,z*scale_z),Vector3(.05,.06,.035),Color("26323b"))
	for z in [.112,.124,.137]:MeshFactory.cylinder(scope,Vector3(0,0,z*scale_z),.050,.006,Color("43505a"),Vector3(PI/2,0,0),-1.,sides)
	MeshFactory.cylinder(scope,Vector3(0,.042,0),.024,.035,Color("303b43"),Vector3.ZERO,-1.,sides)
	MeshFactory.cylinder(scope,Vector3(0,.063,0),.025,.008,Color("63727c"),Vector3.ZERO,-1.,sides)
	MeshFactory.cylinder(scope,Vector3(.043,0,0),.022,.035,Color("303b43"),Vector3(0,0,PI/2),-1.,sides)
	MeshFactory.box(scope,Vector3(0,.068,0),Vector3(.022,.002,.003),Color("bdc9cc"))
	lens(scope,.146*scale_z,.035,"OcularGlass")
	lens(scope,-.172*scale_z,.047,"ObjectiveGlass")
	MeshFactory.merge_children(scope)
