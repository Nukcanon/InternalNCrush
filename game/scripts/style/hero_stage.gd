class_name HeroStage
extends RefCounted
## Style sample of one map district: stone plaza and planted courtyard zones,
## rounded cover, detailed building fronts, readable props and foliage.
## Every group is merged into one cel-shaded mesh.
const S=preload("res://scripts/style/hero_style.gd")
const FRONT=[Color("5f8fc8"),Color("d9a84f"),Color("8a78c4"),Color("4fa98f"),Color("cc7659")]
static func build(parent:Node3D) -> Node3D:
	var root=Node3D.new();root.name="HeroStage";parent.add_child(root)
	var ground=Node3D.new();ground.name="Ground";root.add_child(ground)
	for x in range(-7,8):
		for z in range(-5,4):
			var courtyard=x>2 and z>=0
			var c=(Color("c9b692") if (x+z)%2==0 else Color("bfab86")) if not courtyard else (Color("7aa65f") if (x*3+z)%4!=0 else Color("6f9a56"))
			if absi(x)<=1 and not courtyard:c=Color("d6cab2") if z%2==0 else Color("cbbda2")
			S.rbox(ground,Vector3(x*2.,-.1,z*2.),Vector3(1.94,.2,1.94),c,Vector3.ZERO,.1)
			S.rbox(ground,Vector3(x*2.,-.16,z*2.),Vector3(2.,.1,2.),Color("7d7262"),Vector3.ZERO,.1)
	for x in [-15.,15.]:S.rbox(ground,Vector3(x,.2,-2),Vector3(.7,.6,18),Color("a89878"),Vector3.ZERO,.3)
	var cover=Node3D.new();cover.name="Cover";root.add_child(cover)
	for spec in [[Vector3(-8,0,-3),Vector3(5,1.1,.8)],[Vector3(7,0,-5),Vector3(.8,1.1,4)],[Vector3(2,0,1.5),Vector3(4,1.1,.8)]]:
		var p:Vector3=spec[0];var s:Vector3=spec[1]
		S.rbox(cover,p+Vector3(0,s.y*.5,0),s,Color("cfc8ba"),Vector3.ZERO,.3)
		S.rbox(cover,p+Vector3(0,.12,0),s+Vector3(.14,.24-s.y,.14),Color("8f8676"),Vector3.ZERO,.3)
		S.rbox(cover,p+Vector3(0,s.y+.06,0),s+Vector3(.14,.12-s.y,.14),Color("c25a3f"),Vector3.ZERO,.55)
	var props=Node3D.new();props.name="Props";root.add_child(props)
	for spec in [[Vector3(-4,0,-6),0.],[Vector3(-2.8,0,-6.5),.4],[Vector3(-3.4,1.2,-6.2),.15]]:
		crate(props,spec[0],spec[1])
	for p in [Vector3(9,0,1),Vector3(9.9,0,1.6),Vector3(9.3,0,2.5)]:
		S.cyl(props,p+Vector3(0,.55,0),.42,1.1,Color("2f8c77"))
		for h in [.18,.92]:S.cyl(props,p+Vector3(0,h,0),.44,.07,Color("22695a"))
		S.cyl(props,p+Vector3(0,1.11,0),.32,.03,Color("d9d2bf"))
		S.rbox(props,p+Vector3(0,.55,-.42),Vector3(.28,.2,.02),Color("f2c03e"),Vector3.ZERO,.8)
	# Lamp post, bench and bollards give scale and cover rhythm.
	S.cyl(props,Vector3(-10,.12,4),.18,.24,Color("2f3444"))
	S.cyl(props,Vector3(-10,1.7,4),.07,3.2,Color("39405a"))
	S.rbox(props,Vector3(-9.7,3.25,4),Vector3(.6,.06,.08),Color("39405a"),Vector3.ZERO,.6)
	S.ell(props,Vector3(-9.45,3.1,4),Vector3(.3,.25,.3),Color("f4e2a0"))
	S.rbox(props,Vector3(-6,.45,6),Vector3(2.4,.12,.7),Color("a8703f"),Vector3.ZERO,.5)
	S.rbox(props,Vector3(-6,.75,6.3),Vector3(2.4,.45,.1),Color("a8703f"),Vector3(-.2,0,0),.5)
	for x in [-.9,.9]:S.rbox(props,Vector3(-6+x,.22,6),Vector3(.15,.44,.6),Color("39405a"),Vector3.ZERO,.5)
	for x in [-3.,-1.5,1.5,3.]:
		S.cyl(props,Vector3(x,.4,-9.5),.16,.8,Color("3f4658"))
		S.cyl(props,Vector3(x,.62,-9.5),.17,.07,Color("f2c03e"))
	var foliage=Node3D.new();foliage.name="Foliage";root.add_child(foliage)
	for p in [Vector3(-12,0,-7),Vector3(12,0,-7),Vector3(-12,0,5),Vector3(12,0,6)]:tree(foliage,p)
	for p in [Vector3(4,0,6.2),Vector3(-1,0,-8.5)]:
		S.rbox(foliage,p+Vector3(0,.35,0),Vector3(1.8,.7,1.),Color("b8674e"),Vector3.ZERO,.4)
		S.rbox(foliage,p+Vector3(0,.72,0),Vector3(1.9,.08,1.1),Color("d9d2bf"),Vector3.ZERO,.5)
		for k in range(4):S.ell(foliage,p+Vector3(-.6+k*.4,.9,0),Vector3(.5,.45,.5),Color("e07a9a") if k%2==0 else Color("5f9f52"))
	var fronts=Node3D.new();fronts.name="Fronts";root.add_child(fronts)
	for i in range(5):building(fronts,Vector3(-12+i*6.,0,-12),6.+(i%2)*2.5,FRONT[i],i%2==1)
	S.finish(root)
	return root
static func crate(parent:Node,p:Vector3,yaw:float):
	var r=Vector3(0,yaw,0)
	S.rbox(parent,p+Vector3(0,.6,0),Vector3(1.2,1.2,1.2),Color("b98552"),r,.2)
	for y in [.12,1.08]:S.rbox(parent,p+Vector3(0,y,0),Vector3(1.26,.12,1.26),Color("6e5238"),r,.3)
	S.rbox(parent,p+Vector3(0,.6,0),Vector3(1.24,.14,1.24),Color("8a93a3"),r,.4)
static func tree(parent:Node,p:Vector3):
	S.cyl(parent,p+Vector3(0,1.,0),.24,2.,Color("7d5538"),Vector3.ZERO,.17)
	S.cyl(parent,p+Vector3(0,.08,0),.9,.16,Color("8f8676"))
	S.ell(parent,p+Vector3(0,2.6,0),Vector3(2.6,2.1,2.6),Color("4f9a4c"))
	S.ell(parent,p+Vector3(.7,3.2,.3),Vector3(1.6,1.4,1.6),Color("62ad55"))
	S.ell(parent,p+Vector3(-.6,3.1,-.4),Vector3(1.5,1.3,1.5),Color("43873f"))
	S.ell(parent,p+Vector3(.1,3.6,-.2),Vector3(1.2,1.,1.2),Color("6bb85d"))
static func building(parent:Node,base:Vector3,height:float,color:Color,porch:bool):
	var trim=Color("ddd5c4");var face=base.z+1.
	S.rbox(parent,base+Vector3(0,height*.5,0),Vector3(5.6,height,2),color,Vector3.ZERO,.08)
	S.rbox(parent,base+Vector3(0,.3,0),Vector3(5.8,.6,2.2),color.darkened(.35),Vector3.ZERO,.2)
	# Cornice sits directly on the walls (no floating roof), with a parapet cap.
	S.rbox(parent,base+Vector3(0,height+.15,0),Vector3(5.95,.3,2.3),trim,Vector3.ZERO,.3)
	S.rbox(parent,base+Vector3(0,height+.45,.0),Vector3(5.7,.3,2.),color.darkened(.15),Vector3.ZERO,.25)
	S.rbox(parent,base+Vector3(0,height*.55,0),Vector3(5.7,.18,2.1),trim.darkened(.08),Vector3.ZERO,.3)
	for wx in [-1.5,1.5]:
		for wy in [2.4,height-1.5]:
			var w=Vector3(base.x+wx,wy,face)
			S.rbox(parent,w,Vector3(1.25,1.35,.14),trim,Vector3.ZERO,.25)
			S.rbox(parent,w+Vector3(0,0,.03),Vector3(1.0,1.1,.14),Color("34405a"),Vector3.ZERO,.2)
			S.rbox(parent,w+Vector3(0,0,.07),Vector3(.06,1.1,.06),trim,Vector3.ZERO,.5)
			S.rbox(parent,w+Vector3(0,-.72,.1),Vector3(1.4,.1,.3),trim.darkened(.1),Vector3.ZERO,.4)
	var door=Vector3(base.x,0,face)
	S.rbox(parent,door+Vector3(0,1.2,0),Vector3(1.4,2.4,.14),trim,Vector3.ZERO,.25)
	S.rbox(parent,door+Vector3(0,1.12,.04),Vector3(1.1,2.2,.14),color.darkened(.45),Vector3.ZERO,.2)
	S.rbox(parent,door+Vector3(.35,1.1,.12),Vector3(.08,.08,.06),Color("f2c03e"),Vector3.ZERO,.6)
	S.rbox(parent,door+Vector3(0,.08,.35),Vector3(1.8,.16,.7),trim.darkened(.12),Vector3.ZERO,.3)
	if porch:
		# Awning roof carried by two posts so it never floats.
		S.rbox(parent,door+Vector3(0,2.75,.75),Vector3(2.6,.14,1.6),color.darkened(.25),Vector3(-.12,0,0),.4)
		for x in [-1.15,1.15]:S.cyl(parent,door+Vector3(x,1.35,1.4),.07,2.7,trim.darkened(.2))
	S.cyl(parent,base+Vector3(2.55,height*.5,1.05),.06,height,Color("6f7888"))
static func environment(parent:Node3D):
	var env=Environment.new();env.background_mode=Environment.BG_SKY
	var sky=Sky.new();var mat=ProceduralSkyMaterial.new()
	mat.sky_top_color=Color("5b8ec4");mat.sky_horizon_color=Color("b9cfe0");mat.ground_horizon_color=Color("b9cfe0");mat.ground_bottom_color=Color("7f98ab");mat.sun_angle_max=20
	mat.sky_energy_multiplier=.85
	sky.sky_material=mat;env.sky=sky;env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("ffffff");env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true;env.fog_light_color=Color("b9cfe0");env.fog_density=.008;env.fog_sky_affect=0.
	var world=WorldEnvironment.new();world.environment=env;parent.add_child(world)
# Soft contact shadow under a character: one transparent quad, no shadow maps.
static func blob(parent:Node3D,radius:float=.42) -> MeshInstance3D:
	var quad=MeshInstance3D.new();var mesh=PlaneMesh.new();mesh.size=Vector2.ONE*radius*2.;quad.mesh=mesh
	var m=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;m.albedo_color=Color(.1,.1,.18,.35)
	var img=Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var d=Vector2(x-15.5,y-15.5).length()/15.5;img.set_pixel(x,y,Color(1,1,1,clampf(1.-d*d,0.,1.)))
	m.albedo_texture=ImageTexture.create_from_image(img);quad.material_override=m;quad.position.y=.012;parent.add_child(quad);return quad
