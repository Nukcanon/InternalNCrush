extends RefCounted
class_name WorldSurface
## 1.4 cartoon world surfaces: flat saturated colours with procedural patterns
## (tiles, brick courses, planks, shingles, panels), no texture atlases. Each map
## family has a palette and every quadrant ("zone") of a map gets its own
## colourway, so areas are recognisable at a glance. Shared by native and Web.
static var shader:Shader
static var cache={}
# Pattern ids used by the shader.
const PLAIN=0
const TILES=1
const BRICKS=2
const PLANKS=3
const SHINGLES=4
const PANELS=5
# Family per map index (regular 0..18, defusal 19..30, practice 31).
static func family(index:int) -> String:
	if index in [0,1,5,21,23,28]:return "port"
	if index in [2,8,11,13,15,20,25,27,29]:return "industrial"
	if index in [3,14]:return "lab"
	if index in [4,18]:return "quarry"
	if index in [10,26]:return "garden"
	if index in [19,24,30]:return "historic"
	if index==22:return "library"
	return "town"
# Per family: wall colours by zone, roof colours by zone, ground, trim, wall pattern.
const PALETTES={
	"town":{"walls":["e0926a","78b3c9","e7c267","8cc2a4"],"roofs":["b5503d","3d6b8c","c2772b","4c8566"],"ground":["c8b89a","b7c0b0","cdb697","bcc3b2"],"trim":"f3eee2","wall_pattern":BRICKS},
	"port":{"walls":["4f8fb8","e3e5df","d8705a","f0c24f"],"roofs":["2f5874","8c9aa3","a34533","b8862f"],"ground":["a9b6b8","b9b3a1","a7b3b3","c1b69d"],"trim":"f4f1e8","wall_pattern":PANELS},
	"industrial":{"walls":["c56d43","6f8c9b","d8b44c","8b9aa4"],"roofs":["4a5663","2f5a61","8a3f2d","5b6470"],"ground":["a6aca8","b0a896","9fa9ab","b4ab98"],"trim":"e9c35a","wall_pattern":PANELS},
	"lab":{"walls":["e8eff1","9fd4d7","c8d0ea","f1e2ba"],"roofs":["5e7d95","3f8f95","6b6fa3","b99a50"],"ground":["c9d3d6","bcd0cf","c7cbd9","d3cdb9"],"trim":"4fc3c9","wall_pattern":TILES},
	"quarry":{"walls":["e2b87b","c98e5b","d9caa4","b9a27d"],"roofs":["9a5a38","6e4a33","a8753f","7d6a4d"],"ground":["d2b98a","c4a680","cdbd98","bfa888"],"trim":"f0e2c2","wall_pattern":BRICKS},
	"garden":{"walls":["d99b7b","a9c887","f1d69d","93b9c9"],"roofs":["a4492f","5f7d3f","c47a32","3f6e7e"],"ground":["88b56b","9cbf76","a8bf82","92b870"],"trim":"f4efe2","wall_pattern":PLANKS},
	"historic":{"walls":["e7d0a6","c9a37f","b9c5a9","dab5a1"],"roofs":["9c4a38","6b5a4a","b0673d","5c6e56"],"ground":["cdbd9f","c2b7a0","c9c2a6","d0bba0"],"trim":"f2ead8","wall_pattern":BRICKS},
	"library":{"walls":["c89064","e7d3af","8f6b50","b9a085"],"roofs":["7a3f2c","4f5f6b","9b5a33","6c4a39"],"ground":["b99a78","c7b394","b2987a","c1ab8b"],"trim":"f1e6cc","wall_pattern":PLANKS}}
static func build_shader():
	shader=Shader.new();shader.code="""shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;
// district_surface (1.4 cartoon): flat colour + procedural pattern, no textures.
uniform vec4 tint:source_color=vec4(1.0);
uniform vec4 line_color:source_color=vec4(0.0,0.0,0.0,1.0);
uniform int pattern=0;
uniform float tile_meters=2.0;
uniform float line_strength=.14;
uniform float map_seed=0.;
uniform bool vertex_paint=false;
uniform bool dynamic_lighting=false;
varying vec3 world_p;
varying vec3 world_n;
varying vec3 paint;
void vertex(){
 world_p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 world_n=normalize(MODEL_NORMAL_MATRIX*NORMAL);
 paint=vertex_paint?COLOR.rgb:tint.rgb;
 if(vertex_paint && OUTPUT_IS_SRGB)paint=pow(max(paint,vec3(0.)),vec3(.454545));
}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7))+map_seed*17.)*43758.5453);}
// Distance to the nearest grid line (in cell units), anti-aliased by fwidth.
float grid_line(vec2 uv,float width){
 vec2 f=abs(fract(uv)-.5);vec2 d=(.5-f)/max(fwidth(uv),vec2(1e-4));
 return 1.-clamp(min(d.x,d.y)-width,0.,1.);
}
void fragment(){
 vec3 n=normalize(world_n);
 vec2 uv=(abs(n.y)>.65?world_p.xz:(abs(n.x)>abs(n.z)?world_p.zy:world_p.xy))/tile_meters;
 float line=0.;vec2 cell=floor(uv);
 if(pattern==1){line=grid_line(uv,.6);}
 else if(pattern==2){vec2 b=vec2(uv.x*1.6+.5*mod(floor(uv.y*3.),2.),uv.y*3.);line=grid_line(b,.5);cell=floor(b);}
 else if(pattern==3){vec2 b=vec2(uv.x*4.,uv.y*.5+.37*floor(uv.x*4.));line=grid_line(b,.5);cell=floor(b);}
 else if(pattern==4){vec2 b=vec2(uv.x*2.+.5*mod(floor(uv.y*3.),2.),uv.y*3.);line=grid_line(b,.7);cell=floor(b);}
 else if(pattern==5){vec2 b=vec2(uv.x*.5,uv.y*.33);line=grid_line(b,.5);cell=floor(b);}
 float variation=(hash(cell)-.5)*.07;
 vec3 base=paint*(1.+variation);
 base=mix(base,base*(1.-line_strength*2.2),line);
 // Gentle foot shade grounds walls without an extra pass.
 base*=mix(.9,1.,smoothstep(0.,.9,world_p.y-floor(world_p.y/40.)*40.));
 if(dynamic_lighting){ALBEDO=base*.8;EMISSION=base*.1;}
 else{
  // Unlit (Web/low): bake a fixed cartoon key light into the colour.
  vec3 key=normalize(vec3(.4,.85,.35));float lambert=dot(n*(FRONT_FACING?1.:-1.),key);
  float band=lambert>.55?1.:lambert>.1?.86:.74;
  ALBEDO=vec3(0.);EMISSION=base*band;
 }
 ROUGHNESS=.9;
}
"""
static func material(kind:String,index:int,vertex_paint:bool=false,zone:int=0) -> ShaderMaterial:
	if kind=="quay_edge":kind="wall"
	var key=str([kind,index,vertex_paint,zone])
	if cache.has(key):return cache[key]
	if shader==null:build_shader()
	var palette:Dictionary=PALETTES[family(index)]
	var z=clampi(zone,0,3)
	var color:Color;var pattern=PLAIN;var meters=2.
	match kind:
		"wall","perimeter","tunnel":
			# Bare walls (behind/above facades) share the map style's palette.
			var style=DistrictFacade.style_for(index)
			color=Color(style.colors[z%style.colors.size()]).darkened(.06);pattern=int(style.pattern);meters=2.4
		"ground","lower","waterbed":
			var g=DistrictFacade.GROUNDS.get(DistrictFacade.style_name(index),[palette.ground[z],TILES])
			color=Color(g[0]).lightened(.04*(z%2)).darkened(.03*(z/2));pattern=int(g[1]);meters=2.8 if kind=="ground" else 2.4
		"roof":color=Color(palette.roofs[z]);pattern=SHINGLES;meters=1.6
		"upper":color=Color(palette.roofs[(z+1)%4]).lightened(.18);pattern=PLANKS;meters=2.2
		"soffit","ceiling":
			color=Color(palette.trim).darkened(.08);pattern=PLANKS if kind=="ceiling" else PLAIN;meters=2.
			var ceiling=DistrictFacade.CEILINGS.get(DistrictFacade.style_name(index),[])
			if kind=="ceiling" and not ceiling.is_empty():color=Color(ceiling[0]);pattern=int(ceiling[1]);meters=2.4
		"eave_edge","eave_edge_room","trim":color=Color(palette.trim);pattern=PLAIN
		"stair_detail":color=Color(palette.ground[z]).lightened(.12);pattern=TILES;meters=.9
		"water":color=Color("3f9fbf");pattern=PLAIN
		_:color=Color(palette.walls[z]).lightened(.2)
	var mat=ShaderMaterial.new();mat.shader=shader
	mat.set_shader_parameter("tint",color);mat.set_shader_parameter("pattern",pattern);mat.set_shader_parameter("tile_meters",meters)
	mat.set_shader_parameter("vertex_paint",vertex_paint);mat.set_shader_parameter("map_seed",float(index))
	mat.set_shader_parameter("line_strength",.10 if kind in ["ground","lower"] else .14)
	mat.set_shader_parameter("dynamic_lighting",GraphicsOptions.lighting>0)
	cache[key]=mat;return mat
