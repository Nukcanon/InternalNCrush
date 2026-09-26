class_name BulletMark
extends RefCounted
## One transparent quad per impact, shared materials; no extra lights or geometry holes.
static var meshes:Dictionary={}
static var materials:Dictionary={}
static func make(web:bool) -> MeshInstance3D:
	var variant=randi_range(0,7);var key=str(web)+str(variant)
	if not meshes.has(web):
		var mesh=PlaneMesh.new();mesh.size=Vector2.ONE*(.115 if web else .155);meshes[web]=mesh
	if not materials.has(key):
		var material=ShaderMaterial.new();var shader=Shader.new()
		shader.code=CODE;material.shader=shader;material.set_shader_parameter("fine_detail",not web);material.set_shader_parameter("seed",float(variant)*7.31);materials[key]=material
	var mark=MeshInstance3D.new();mark.mesh=meshes[web];mark.material_override=materials[key]
	mark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not web:add_relief(mark,variant)
	return mark
static func add_relief(mark:MeshInstance3D,variant:int):
	var key="relief"+str(variant)
	if not meshes.has(key):
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Shallow chipped rim: actual lit facets around the opaque cavity.
		for i in range(18):
			var a=i*TAU/18.;var b=(i+1)*TAU/18.
			var ra=.044+sin(i*7.7+variant)*.008;var rb=.044+sin((i+1)*7.7+variant)*.008
			var inner_a=Vector3(cos(a)*.023,.001,sin(a)*.023);var inner_b=Vector3(cos(b)*.023,.001,sin(b)*.023)
			var outer_a=Vector3(cos(a)*ra,.004+absf(sin(i*4.1))*.004,sin(a)*ra);var outer_b=Vector3(cos(b)*rb,.004+absf(sin((i+1)*4.1))*.004,sin(b)*rb)
			for v in [inner_a,outer_b,outer_a,inner_a,inner_b,outer_b]:st.add_vertex(v)
		st.generate_normals();meshes[key]=st.commit()
	var rim=MeshInstance3D.new();rim.mesh=meshes[key];mark.add_child(rim)
	if not materials.has("rim"):
		var mat=StandardMaterial3D.new();mat.albedo_color=Color("766e5f");mat.roughness=.93;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;materials.rim=mat
	rim.material_override=materials.rim;rim.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
const CODE="""
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform bool fine_detail = true;
uniform float seed = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))+seed)*43758.5453); }
void fragment() {
	vec2 p=(UV-0.5)*2.0;
	float radius=length(p);
	float angle=atan(p.y,p.x)+seed;
	float chipped=sin(angle*7.0)*0.035+sin(angle*13.0+1.7)*0.022;
	float edge=radius+chipped;
	float core=1.0-smoothstep(0.23,0.31,edge);
	float crater=1.0-smoothstep(0.39,0.52,edge);
	float dust=(1.0-smoothstep(0.42,0.88,radius))*0.25;
	float bevel=smoothstep(0.23,0.32,edge)*(1.0-smoothstep(0.38,0.53,edge));
	float light=clamp(dot(normalize(p+vec2(0.0001)),normalize(vec2(-0.6,-0.8)))*0.5+0.5,0.0,1.0);
	vec3 color=mix(vec3(0.15,0.14,0.12),vec3(0.55,0.52,0.46),light)*bevel+vec3(0.12)*(1.0-bevel);
	float alpha=max(crater,dust);
	if (fine_detail) {
		// Thin, irregular radial fractures and faceted inner rim.
		float fracture=abs(sin(angle*4.0+sin(radius*19.0+seed)*0.09));
		float cracks=(1.0-smoothstep(0.018,0.046,fracture))*smoothstep(0.34,0.45,radius)*(1.0-smoothstep(0.62,0.89,radius));
		float grain=hash(floor(UV*180.0));
		color*=0.78+grain*0.40;
		color+=vec3(0.18)*bevel*step(0.75,grain)*light;
		color=mix(color,vec3(0.07,0.06,0.05),cracks);
		alpha=max(alpha,cracks*0.8);
		// Off-centre inner shadow gives the crater depth without added polygons.
		float cavity=1.0-smoothstep(0.15,0.26,length(p+vec2(0.035,-0.03))+chipped);
		core=max(core*0.82,cavity);
	}
	ALBEDO=mix(color,vec3(0.015,0.012,0.01),core);
	ALPHA=alpha;
}
"""
