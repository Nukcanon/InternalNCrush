extends RefCounted
class_name SurfaceFinish
static var equipment:ShaderMaterial
static var architecture:ShaderMaterial
static var humans={}
static var hand_materials={}
static func human_material(role:int=0) -> ShaderMaterial:
	if humans.has(role):return humans[role]
	var shader=Shader.new();shader.code="""
shader_type spatial;
uniform sampler2D operator_atlas:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D skin_texture:source_color,filter_linear_mipmap_anisotropic;
varying vec3 p;
varying vec3 local_normal;
void vertex(){p=VERTEX;local_normal=NORMAL;}
void fragment(){
 float kind=floor(UV2.y+.1);vec3 n=abs(local_normal);
 vec2 coords=n.y>.65?p.xz:(n.x>n.z?p.zy:p.xy);
 float density=kind==1.?3.5:8.;
 vec2 tile=vec2(mod(kind,2.),floor(kind/2.))*.5;
 vec2 uv=tile+.003+abs(fract(coords*density)*2.-1.)*.494;
 vec3 tex=texture(operator_atlas,uv).rgb;
 if(OUTPUT_IS_SRGB){tex=pow(tex,vec3(2.2));}
 float lum=dot(tex,vec3(.2126,.7152,.0722));
 float mid=kind==0.?.35:kind==1.?.14:kind==2.?.075:.085;
 float relief=clamp(lum/max(.04,mid),.55,1.6);
 ALBEDO=COLOR.rgb*mix(1.,relief,kind==3.?.55:.32);
 if(kind==0.){
   vec3 skin=texture(skin_texture,UV).rgb;
   if(OUTPUT_IS_SRGB){skin=pow(skin,vec3(2.2));}
   float grey=dot(skin,vec3(.2126,.7152,.0722));
   ALBEDO=mix(skin,vec3(grey),.20)*vec3(.94,1.,1.02)*.72;
 }
 ROUGHNESS=clamp(UV2.x+(relief-1.)*.10,.58,.97);
 METALLIC=0.;SPECULAR=kind==0.?.24:.14;
}
"""
	var human=ShaderMaterial.new();human.shader=shader
	human.set_shader_parameter("operator_atlas",load("res://assets/textures/operator_materials_v11.png"))
	human.set_shader_parameter("skin_texture",load("res://assets/human/textures/"+["male","female","male_dark","male","male_dark","female_asian"][role]+".png"))
	humans[role]=human;return human
static func hand_material(color:Color,kind:int) -> ShaderMaterial:
	var key=str(color)+str(kind)
	if hand_materials.has(key):return hand_materials[key]
	var shader=Shader.new();shader.code="""
shader_type spatial;
uniform sampler2D operator_atlas:source_color,filter_linear_mipmap_anisotropic;
uniform vec4 tint:source_color;
uniform float kind=0.;
varying vec3 p;varying vec3 n;
void vertex(){p=VERTEX;n=NORMAL;}
void fragment(){
 vec3 a=abs(n);vec2 coords=a.y>.65?p.xz:(a.x>a.z?p.zy:p.xy);
 vec2 tile=vec2(mod(kind,2.),floor(kind/2.))*.5;
 vec3 t=texture(operator_atlas,tile+.003+abs(fract(coords*(kind==1.?3.5:8.))*2.-1.)*.494).rgb;
 if(OUTPUT_IS_SRGB){t=pow(t,vec3(2.2));}
 float mid=kind==0.?.35:kind==1.?.14:.075;
 float detail=clamp(dot(t,vec3(.2126,.7152,.0722))/mid,.6,1.5);
 ALBEDO=tint.rgb*mix(1.,detail,.32);ROUGHNESS=kind==0.?.7:.89;SPECULAR=.2;
}
"""
	var mat=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("tint",color);mat.set_shader_parameter("kind",float(kind));mat.set_shader_parameter("operator_atlas",load("res://assets/textures/operator_materials_v11.png"));hand_materials[key]=mat;return mat
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
uniform bool rich_detail=false;
uniform float finish_roughness=-1.0;
uniform float finish_metallic=-1.0;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float footprint=length(fwidth(p));
 float grain=rich_detail?sin(p.x*155.0)*sin(p.y*137.0)*sin(p.z*163.0):0.;
 float weave=rich_detail?sin(p.x*410.0)*sin(p.y*405.0):0.;
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
uniform bool rich_detail=false;
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
 float large=.5;float fine=0.;
 if(rich_detail){large=noise(p*.65);fine=(noise(p*22.)-.5)*clamp(1.-length(fwidth(p))*12.,0.,1.);}
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
