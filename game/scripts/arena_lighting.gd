extends RefCounted
class_name ArenaLighting
static func build(a:Node):
	var night=bool(a.get_meta("night",false));var indoor=a.indoors
	var world=WorldEnvironment.new();world.name="Environment";var env=Environment.new();env.background_mode=Environment.BG_SKY
	var sky=Sky.new();var sky_mat=ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("101f3d") if night else Color("6d94b4");sky_mat.sky_horizon_color=Color("43567a") if night else Color("dad4c1");sky_mat.ground_horizon_color=sky_mat.sky_horizon_color;sky_mat.ground_bottom_color=Color("1e2c37") if night else Color("746b58");sky.sky_material=sky_mat;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("9bafcb") if night else Color("c8d5e2");env.ambient_light_energy=.48 if indoor else .34 if night else .38
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure=1.15
	env.fog_enabled=not indoor;env.fog_density=.0009 if night else .00045;env.fog_light_color=Color("596f91") if night else Color("bdc9ce");env.fog_sky_affect=.35
	world.environment=env;a.add_child(world)
	var sun=DirectionalLight3D.new();sun.name="Sun";sun.rotation_degrees=Vector3(-38,-32,0) if night else Vector3(-48,-28,0);sun.light_color=Color("90b4ff") if night else Color("ffedce");sun.light_energy=.58 if a.get_meta("hybrid",false) else .18 if indoor else .32 if night else 1.1;sun.shadow_enabled=not indoor or bool(a.get_meta("hybrid",false));sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS;sun.directional_shadow_max_distance=90.;sun.shadow_bias=.25;sun.shadow_normal_bias=1.5;a.add_child(sun)
	var points=[]
	if indoor or night:
		for x in [-.60,0.,.60]:
			for z in [-.60,.0,.60]:points.append(Vector3(x*a.bounds.x,7.2 if indoor else 5.8,z*a.bounds.y))
	if a.vertical_map:
		for z in [-7.,7.]:points.append(Vector3(0,-.4,z))
	for i in range(points.size()):
		var point:Vector3=points[i];var warm=i%2==0;var color=Color("ffd49a") if warm else Color("a3d9ed")
		var light=OmniLight3D.new();light.position=point;light.name="Practical"+str(i);light.light_color=color;light.light_energy=1.8 if indoor else 2.2;light.omni_range=18. if point.y>0 else 8.;light.omni_attenuation=1.3;light.shadow_enabled=i<4;light.distance_fade_enabled=true;light.distance_fade_begin=55.;light.distance_fade_length=12.;a.add_child(light)
		var fixture=MeshFactory.box(a,point,Vector3(1.1,.13,.40),Color("354452"));fixture.name="Luminaire"
		var lens=MeshFactory.box(a,point-Vector3.UP*.075,Vector3(.93,.035,.29),color)
		var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=1.6;lens.material_override=mat;lens.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not indoor and point.y>0:MeshFactory.cylinder(a,point+Vector3(.6,-point.y*.5,0),.06,point.y,Color("415361"))
	a.set_meta("practical_lights",points.size())
