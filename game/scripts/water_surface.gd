class_name WaterSurface
extends RefCounted
## Water surfaces. 1.4.6 (the user): deep water (rivers, canals, the sea: 2 m
## and more, deadly) is dark blue and fully opaque - nothing below shows;
## shallow water (0.5 m at most, safe) is a very light, see-through blue. Both
## move like water (rolling waves, glints of light, ripple lines and a sky
## reflection at grazing angles), never like flat ground.
static var cache={}
static func material(sea:bool) -> ShaderMaterial:return material_kind("sea" if sea else "river")
static func material_kind(kind:String) -> ShaderMaterial:
	if cache.has(kind):return cache[kind]
	var clear=kind=="shallow"
	var shader=Shader.new();shader.code="""shader_type spatial;
render_mode cull_disabled%s;
uniform vec3 water_colour:source_color=vec3(.06,.32,.39);
uniform vec3 sky_colour:source_color=vec3(.72,.84,.95);
uniform float wave_size=1.;
uniform float alpha=1.;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 p=world.xz*wave_size;float t=TIME;
 float detail=1.-smoothstep(35.,170.,length(VERTEX));
 // rolling waves: a few travelling sines, their slopes bend the normal
 vec2 g=vec2(0.);float h=0.;
 vec2 d0=normalize(vec2(1.,.35));vec2 d1=normalize(vec2(-.45,1.));vec2 d2=normalize(vec2(.8,-.6));vec2 d3=normalize(vec2(-1.,-.2));
 float ph;
 ph=dot(d0,p)*.9+t*1.1;h+=.06*sin(ph);g+=.06*.9*cos(ph)*d0;
 ph=dot(d1,p)*1.7-t*1.4;h+=.035*sin(ph);g+=.035*1.7*cos(ph)*d1;
 ph=dot(d2,p)*3.1+t*2.;h+=.018*sin(ph);g+=.018*3.1*cos(ph)*d2;
 ph=dot(d3,p)*5.3+t*2.6;h+=.009*sin(ph);g+=.009*5.3*cos(ph)*d3;
 g*=detail*1.6;
 vec3 n=normalize(vec3(-g.x,1.,-g.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(n,0.)).xyz);
 if(!FRONT_FACING)NORMAL=-NORMAL;
 float fresnel=pow(1.-clamp(dot(NORMAL,VIEW),0.,1.),3.);
 // bright ripple lines riding on the crests
 float r=sin(dot(p,vec2(1.3,.7))*2.4+t*1.6+h*30.+sin(dot(p,vec2(-.6,1.1))*1.3-t*.8)*1.6);
 float line=smoothstep(.94,.997,r)*detail;
 vec3 colour=mix(water_colour,sky_colour,fresnel*.55)+vec3(.55,.65,.7)*line*%s;
 ALBEDO=colour;ROUGHNESS=.06;SPECULAR=.85;METALLIC=0.;
 %s
}
"""%([", blend_mix, depth_draw_opaque" if clear else "", ".35" if clear else ".22", "ALPHA=clamp(alpha+fresnel*.3+line*.15,0.,1.);" if clear else ""])
	var result=ShaderMaterial.new();result.shader=shader
	var looks={"sea":[Color("0d3b8c"),.55,1.],"river":[Color("123f86"),.9,1.],"shallow":[Color("8fd2ff"),1.3,.46]}
	var look:Array=looks.get(kind,looks.river)
	result.set_shader_parameter("water_colour",look[0]);result.set_shader_parameter("wave_size",look[1]);result.set_shader_parameter("alpha",look[2])
	if clear:result.render_priority=1
	cache[kind]=result;return result
