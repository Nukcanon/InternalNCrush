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
# 1.5 relief maps (assets/textures/detail, baked from CC0 ambientCG materials by
# tools/maps/fetch_textures.py): slot -> [metres per repeat, strength].
const DETAILS={"asphalt":[3.,.30],"concrete":[3.5,.22],"paving":[2.6,.30],"cobble":[2.6,.34],"setts":[2.,.34],"sand":[3.,.26],
	"dirt":[3.,.30],"gravel":[2.4,.32],"grass":[2.4,.30],"steel_floor":[1.4,.28],"wood_floor":[2.6,.30],"planks":[2.6,.32],
	"tiles_white":[2.4,.22],"tiles_stone":[3.6,.24],"brick_red":[1.8,.30],"brick_yellow":[1.8,.30],"brick_old":[2.,.32],
	"stone_wall":[2.6,.32],"plaster":[3.,.22],"concrete_wall":[3.,.24],"corrugated":[2.2,.30],"rock":[4.,.34],"roof_tiles":[2.,.34],"rust":[3.,.28]}
# Facade/bare wall, outdoor ground and indoor floor relief per map style.
const STYLE_WALL={"oldtown":"plaster","hillside":"plaster","canal":"brick_red","plaza":"plaster","market":"brick_yellow","station":"brick_red",
	"harbour":"corrugated","shipyard":"corrugated","logistics":"corrugated","desert":"plaster","orchard":"planks","quarry":"stone_wall",
	"fortress":"stone_wall","mountain_fort":"stone_wall","monastery":"plaster","aqueduct":"brick_old","nuclear":"concrete_wall","wreckyard":"rust",
	"furnace":"brick_old","greenhouse":"tiles_white","coastal_base":"concrete_wall","range":"planks","steelmill":"brick_old","lab":"tiles_white",
	"garage":"concrete_wall","power":"concrete_wall","testlab":"tiles_white","derelict":"brick_old","highrise":"plaster","library":"planks",
	"vault":"concrete_wall","server":"tiles_white"}
const STYLE_GROUND={"oldtown":"cobble","hillside":"paving","canal":"setts","plaza":"paving","market":"setts","station":"tiles_stone",
	"harbour":"concrete","shipyard":"concrete","logistics":"asphalt","desert":"sand","orchard":"dirt","quarry":"gravel","fortress":"setts",
	"mountain_fort":"cobble","monastery":"tiles_stone","aqueduct":"cobble","nuclear":"concrete","wreckyard":"gravel","furnace":"steel_floor",
	"greenhouse":"paving","coastal_base":"concrete","range":"dirt","steelmill":"steel_floor","lab":"tiles_white","garage":"concrete",
	"power":"steel_floor","testlab":"tiles_white","derelict":"concrete","highrise":"wood_floor","library":"wood_floor","vault":"steel_floor","server":"tiles_white"}
static var detail_maps={}
static func detail_texture(slot:String) -> Texture2D:
	if not detail_maps.has(slot):
		var path="res://assets/textures/detail/%s.png"%slot
		detail_maps[slot]=load(path) if ResourceLoader.exists(path) else null
	return detail_maps[slot]
static func detail_slot(kind:String,index:int) -> String:
	var style=DistrictFacade.style_name(index);var fam=family(index)
	var ground=STYLE_GROUND.get(style,"concrete")
	match kind:
		"wall","perimeter","tunnel","skin":return STYLE_WALL.get(style,"concrete_wall")
		"ground","lower":return ground
		"waterbed":return "gravel"
		"plaza":return {"sand":"paving","dirt":"paving","gravel":"concrete","asphalt":"concrete","steel_floor":"concrete"}.get(ground,ground)
		"indoor":return "wood_floor" if fam in ["town","garden","library","historic"] else "tiles_stone" if fam in ["lab","quarry"] else "concrete"
		"stair_ramp","stair_detail":return "concrete" if fam in ["port","industrial","lab"] else "tiles_stone"
		"roof":return "corrugated" if fam in ["port","industrial","lab"] else "roof_tiles"
		"upper":return "steel_floor" if fam=="industrial" else "planks"
		"ceiling":return {TILES:"tiles_white",PLANKS:"planks",PANELS:"concrete_wall"}.get(int(DistrictFacade.CEILINGS.get(style,["",PLANKS])[1]),"plaster")
		"soffit":return "plaster"
	return ""
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
// 1.5: grey relief map (joints, grain, ridges) modulating the palette colour.
uniform sampler2D detail_map:hint_default_white,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float detail_meters=2.;
uniform float detail_strength=0.;
uniform bool texture_detail=true;
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
 if(detail_strength>0.){
  vec2 duv=vec2(uv.x,-uv.y)*tile_meters/detail_meters;
  // Soft 9 m value noise breaks up visible repeats of the relief map.
  vec2 m=world_p.xz/9.+world_p.y*.07;vec2 i=floor(m);vec2 f=smoothstep(0.,1.,fract(m));
  float macro=mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
  base*=1.+(macro-.5)*.10;
  if(texture_detail)base*=1.+(texture(detail_map,duv).r-.5)*2.*detail_strength;
 }
 // Gentle foot shade grounds walls without an extra pass.
 base*=mix(.9,1.,smoothstep(0.,.9,world_p.y-floor(world_p.y/40.)*40.));
 // 1.4.2: a little less self-light, so shade and cast shadows read deeper.
 if(dynamic_lighting){ALBEDO=base*.82;EMISSION=base*.05;}
 else{
  // Unlit (Web/low): bake a fixed cartoon key light into the colour.
  vec3 key=normalize(vec3(.4,.85,.35));float lambert=dot(n*(FRONT_FACING?1.:-1.),key);
  float band=lambert>.55?1.:lambert>.1?.83:.68;
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
		# 1.5 blueprints: paved plazas and covered-room floors read as their own spaces.
		"plaza":
			var g=DistrictFacade.GROUNDS.get(DistrictFacade.style_name(index),[palette.ground[z],TILES])
			color=Color(g[0]).lightened(.10).lerp(Color(palette.trim),.12);pattern=TILES;meters=1.6
		"indoor":
			var floor=DistrictFacade.GROUNDS.get(DistrictFacade.style_name(index),[palette.ground[z],TILES])
			color=Color(floor[0]).darkened(.18).lerp(Color(palette.roofs[z]),.18);pattern=PLANKS if int(floor[1])==PLANKS else TILES;meters=2.0
		"stair_ramp":color=Color(palette.ground[z]).lightened(.06);pattern=TILES;meters=.9
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
	apply_detail(mat,detail_slot(kind,index),kind in ["stair_ramp","stair_detail"])
	cache[key]=mat;return mat
## Relief replaces the procedural joint lines (the photo-derived map has its own);
## stairs keep their tread lines so steps still read from a distance.
static func apply_detail(mat:ShaderMaterial,slot:String,keep_pattern:=false):
	var texture=detail_texture(slot) if DETAILS.has(slot) else null
	if texture==null:return
	mat.set_shader_parameter("detail_map",texture)
	if not keep_pattern:mat.set_shader_parameter("pattern",PLAIN)
	mat.set_shader_parameter("detail_meters",float(DETAILS[slot][0]));mat.set_shader_parameter("detail_strength",float(DETAILS[slot][1]))
	mat.set_shader_parameter("texture_detail",GraphicsOptions.relief())
