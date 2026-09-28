extends RefCounted
class_name WorldSurface
## One texture lookup, no lights/shadows required. Shared native/Web identity.
static var shader:Shader
static var cache={}
# Wall material / floor material / wall tint. Keep destinations recognizable
# without a separate shader or extra texture passes for every district.
const THEMES=[
	["painted","paving","d5e6e7"], ["rust","concrete","d0c4b6"],
	["brick","metal","bfa38d"], ["plaster","paving","dce5e7"],
	["sandstone","earth","e8cf9b"], ["stone","paving","c6d7d4"],
	["brick","paving","d8bcac"], ["plaster","paving","e8cfaa"],
	["concrete","metal","b9c8d8"], ["plaster","paving","deccb3"],
	["wood","moss","cab393"], ["concrete","metal","c3ced0"],
	["sandstone","paving","e6ded0"], ["rust","concrete","c7c8c3"],
	["plaster","paving","dde6e8"], ["brick","concrete","c6a491"],
	["concrete","paving","c6d5dc"], ["brick","paving","e8cfaa"],
	["stone","earth","cbbca1"], ["sandstone","paving","ded0b0"],
	["concrete","metal","cad9d5"], ["stone","paving","c8dedb"],
	["brick","wood","d6c4af"], ["rust","wood","c3cbc1"],
	["sandstone","moss","ded8c9"], ["brick","metal","c3a88b"],
	["plaster","moss","c8ddbc"], ["metal","concrete","b4c1cf"],
	["stone","paving","c3d7df"], ["concrete","metal","c1d9db"],
	["sandstone","moss","d6c5a2"], ["concrete","paving","c7d3d1"]]
static func material(kind:String,index:int,vertex_paint:bool=false,zone:int=0) -> ShaderMaterial:
	var key=str([kind,index,vertex_paint,zone])
	if cache.has(key):return cache[key]
	if shader==null:
		shader=Shader.new();shader.code="""shader_type spatial;
render_mode cull_disabled, specular_disabled;
// district_surface: never replace this material with flat Web paint.
uniform sampler2D surface_texture:source_color,filter_linear_mipmap,repeat_enable;
uniform vec4 tint:source_color=vec4(1.0);
uniform float tile_meters=3.0;
uniform bool vertex_paint=false;
uniform bool dynamic_lighting=false;
varying vec2 surface_uv;
varying vec3 surface_n;
varying vec3 surface_p;
varying vec3 paint;
void vertex(){
 surface_p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 surface_n=normalize(MODEL_NORMAL_MATRIX*NORMAL);
 vec3 n=abs(surface_n);
 surface_uv=(n.y>.65?surface_p.xz:(n.x>n.z?surface_p.zy:surface_p.xy))/tile_meters;
 paint=vertex_paint?COLOR.rgb:tint.rgb;
 if(vertex_paint && OUTPUT_IS_SRGB)paint=pow(max(paint,vec3(0.)),vec3(.454545));
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 vec3 tex=texture(surface_texture,surface_uv).rgb;
 vec3 n=normalize(surface_n);if(!FRONT_FACING)n=-n;
 float facing=.82+.18*max(0.,dot(n,normalize(vec3(.35,.85,.4))));
 // Never modulo interpolated height: at a storey boundary subpixel rounding
 // alternated between dark and light, looking exactly like z-fighting.
 float foot=mix(.94,1.,smoothstep(0.,.8,surface_p.y));
 float variation=.96+.04*sin(surface_p.x*.17+surface_p.z*.23);
 vec3 base=paint*mix(vec3(.98),sqrt(max(tex,vec3(0.))),vertex_paint?.16:.62)*foot*variation;
 ALBEDO=dynamic_lighting?base*.78:vec3(0.);
 EMISSION=dynamic_lighting?base*.22:base*facing;
 ROUGHNESS=.86;
}
"""
	var market=index in [7,9,12,17,19,22,24,30];var coast=index in [0,1,5,21,23,28];var garden=index in [10,26]
	var texture="brick" if market else "stone" if coast else "concrete"
	var color=Color("e8cfaa") if market else Color("c6d7d4") if coast else Color("b4c3ce")
	var meters=3.
	match kind:
		"ground":texture="earth" if garden else "paving" if market or coast else "concrete";color=Color("b7ac90") if market else Color("859b78") if garden else Color("829795");meters=3.2
		"upper":texture="wood" if market or coast else "metal";color=Color("d1a86e") if market or coast else Color("b2c7d0");meters=2.4
		"lower":texture="paving";color=Color("90a9b3");meters=2.8
		"tunnel":texture="brick";color=Color("adc5c9")
		"roof":texture="roof";color=Color("ba7860") if market else Color("718994")
		"ceiling":texture="wood" if market else "concrete";color=Color("bac8cc")
		"water":texture="concrete";color=Color("478ca1");meters=8.
		"trim":texture="metal";color=Color("cfaa63");meters=2.
		"stair_detail":texture="concrete";color=Color("c0cdd0");meters=2.4
		"detail":texture="concrete";color=Color.WHITE;meters=1.8
	if index>=0 and index<THEMES.size():
		if kind in ["wall","perimeter"]:texture=THEMES[index][0];color=Color(THEMES[index][2])
		elif kind=="ground":texture=THEMES[index][1]
	# Material families keep a laboratory sterile and a quay maritime. Region
	# variation must not randomly put moss/wood flooring inside a power station.
	if zone>0 and kind in ["ground","wall","perimeter"]:
		var family="town"
		if index in [0,1,5,21,23,28]:family="port"
		elif index in [2,8,11,13,15,20,25,27,29]:family="industrial"
		elif index in [3,14]:family="lab"
		elif index in [4,18]:family="quarry"
		elif index in [10,26]:family="garden"
		elif index in [19,24,30]:family="historic"
		elif index==22:family="library"
		var families={
			"town":[["paving","concrete","paving","wood"],["plaster","brick","painted","stone"],["d7c6a5","b4c7bf","e2c5ad","d1c7b4"]],
			"port":[["concrete","paving","wood","metal"],["painted","stone","brick","rust"],["c5dce0","d9d0b7","c8bbab","d3bd9c"]],
			"industrial":[["concrete","metal","concrete","paving"],["concrete","painted","brick","metal"],["c5d1cb","9dbfc4","d0b59a","c4cbd3"]],
			"lab":[["paving","concrete","paving","metal"],["plaster","painted","concrete","plaster"],["dce9e7","b1d3cf","c7d7e2","e5d9bb"]],
			"quarry":[["earth","stone","concrete","earth"],["sandstone","stone","rust","sandstone"],["dfc695","c7bfa9","c9ba9c","e6d3aa"]],
			"garden":[["earth","moss","paving","wood"],["wood","plaster","stone","brick"],["d0c397","d2dfba","c8d0b4","d8bc96"]],
			"historic":[["paving","stone","moss","paving"],["sandstone","stone","plaster","brick"],["e1d3b3","c6cbb5","e8d8bf","d5b89c"]],
			"library":[["wood","paving","wood","paving"],["plaster","wood","brick","stone"],["e7d8ba","c3af8f","d4bda2","d9d5c4"]]}
		var recipe=families[family]
		if kind=="ground":
			texture=recipe[0][zone%4];color=Color(recipe[2][zone%4]).darkened(.12)
		else:
			texture=recipe[1][zone%4];color=Color(recipe[2][zone%4])
	if kind=="stair_detail":texture=THEMES[index][1];color=Color("c7c9b6");meters=2.4
	var mat=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("surface_texture",load("res://assets/textures/world/"+texture+".png"));mat.set_shader_parameter("tint",color);mat.set_shader_parameter("tile_meters",meters);mat.set_shader_parameter("vertex_paint",vertex_paint)
	cache[key]=mat;return mat
