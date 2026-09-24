extends RefCounted
class_name SurfaceFinish
static var equipment:ShaderMaterial
static var architecture:ShaderMaterial
static func material_kind(color:Color) -> int:
	var hex=color.to_html(false)
	if hex in ["ae8b5d","dbc099","d0b186","c8a577","87745a","987851","b18b61"]:return 2
	if hex in ["536e7b","3a515b","47636c","354954","3faaa4","608e90","b06d57","839da2","4e646e","314c59"]:return 1
	if hex in ["a2acaa","738185","566268"]:return 3
	return 0
static func equipment_material() -> ShaderMaterial:
	if equipment:return equipment
	var shader=Shader.new();shader.code="""
shader_type spatial;
uniform float finish_roughness=-1.0;
uniform float finish_metallic=-1.0;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float footprint=length(fwidth(p));
 float grain=sin(p.x*155.0)*sin(p.y*137.0)*sin(p.z*163.0);
 float weave=sin(p.x*410.0)*sin(p.y*405.0);
 float cloth=step(.75,UV2.x)*(1.0-clamp(UV2.y,0.,1.));
 float detail=mix(grain*.022,weave*.025,cloth)*clamp(1.0-footprint*140.0,0.0,1.0);
 ALBEDO=COLOR.rgb*(1.0+detail);
 ROUGHNESS=clamp(UV2.x+detail,.24,.96);METALLIC=clamp(UV2.y,0.,1.);
 if(finish_roughness>=0.0){ROUGHNESS=finish_roughness;}
 if(finish_metallic>=0.0){METALLIC=finish_metallic;}
 SPECULAR=mix(.35,.58,clamp(UV2.y,0.,1.));
}
void light(){
 float d=max(dot(NORMAL,LIGHT),0.0);
 float band=.18*smoothstep(.0,.12,d)+.40*smoothstep(.28,.46,d)+.42*smoothstep(.70,.90,d);
 DIFFUSE_LIGHT+=ALBEDO*LIGHT_COLOR*ATTENUATION*band/3.14159265;
 vec3 h=normalize(LIGHT+VIEW);
 SPECULAR_LIGHT+=LIGHT_COLOR*ATTENUATION*pow(max(dot(NORMAL,h),0.0),mix(64.,12.,ROUGHNESS))*(.08+METALLIC*.28);
}
"""
	equipment=ShaderMaterial.new();equipment.shader=shader;return equipment
static func world_material() -> ShaderMaterial:
	if architecture:return architecture
	var shader=Shader.new();shader.code="""
shader_type spatial;
uniform sampler2D material_atlas:source_color,filter_linear_mipmap_anisotropic;
varying vec3 p;varying vec3 n;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;n=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
float hash(vec3 x){return fract(sin(dot(x,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 x){vec3 i=floor(x);vec3 f=fract(x);f=f*f*(3.0-2.0*f);
return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void fragment(){
 vec3 normal=abs(n);bool floor_face=normal.y>.65;
 vec2 uv=floor_face?p.xz:(normal.x>normal.z?p.zy:p.xy);
 vec2 tiles=floor_face?uv*.25:vec2(uv.x*1.3+mod(floor(uv.y*2.8),2.0)*.5,uv.y*2.8);
 vec2 f=fract(tiles);vec2 aa=max(fwidth(tiles)*1.3,vec2(.006));
 float seam=min(smoothstep(vec2(.018),vec2(.018)+aa,min(f,1.0-f)).x,smoothstep(vec2(.018),vec2(.018)+aa,min(f,1.0-f)).y);
 float large=noise(p*.65);float fine=(noise(p*22.)-.5)*clamp(1.-length(fwidth(p))*12.,0.,1.);
 float kind=max(0.,-UV2.y-1.);float metal=max(0.,UV2.y);float rough=UV2.x;
 float mortar=mix(floor_face?.94:.87,1.,seam);
 float patina=.92+large*.14+fine*.06;
 vec2 tile=vec2(mod(kind,2.),floor(kind/2.))*.5;
 vec2 mirrored=abs(fract(uv*(kind==2.?.18:.32)) *2.-1.);
 vec3 texture_color=texture(material_atlas,tile+vec2(.003)+mirrored*.494).rgb;
 float detail=dot(texture_color,vec3(.333));
 float midpoint=kind==0.?.48:kind==1.?.30:kind==2.?.22:.12;
 float tactile=clamp(detail/max(midpoint,.08),.48,1.45);
 ALBEDO=COLOR.rgb*mix(1.,tactile,.32)*patina*mix(1.,mortar,step(.85,rough)*(1.-metal)*.3);
 ROUGHNESS=clamp(rough+(large-.5)*.10+(detail-midpoint)*.20,.28,.98);METALLIC=metal;SPECULAR=.30;
}
"""
	architecture=ShaderMaterial.new();architecture.shader=shader;architecture.set_shader_parameter("material_atlas",load("res://assets/textures/field_materials_v103.png"));return architecture
