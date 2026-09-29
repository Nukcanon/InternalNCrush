class_name HeroStage
extends RefCounted
## Style sample of one map district: painted ground zones, rounded cover,
## readable props and foliage. Every group is merged into one cel-shaded mesh.
const S=preload("res://scripts/style/hero_style.gd")
static func build(parent:Node3D) -> Node3D:
	var root=Node3D.new();root.name="HeroStage";parent.add_child(root)
	var ground=Node3D.new();ground.name="Ground";root.add_child(ground)
	# Plaza tiles in two tones plus a warm path and a cool courtyard zone.
	for x in range(-7,8):
		for z in range(-5,4):
			var warm=z>=0
			var c=(Color("f3d9a4") if (x+z)%2==0 else Color("ecca8d")) if warm else (Color("bfe3d0") if (x+z)%2==0 else Color("a9d6c0"))
			if absi(x)<=1:c=Color("f7efe0") if (z%2==0) else Color("efe4cf")
			S.rbox(ground,Vector3(x*2.,-.1,z*2.),Vector3(1.96,.2,1.96),c,Vector3.ZERO,.08)
	for x in [-15.,15.]:S.rbox(ground,Vector3(x,.15,-2),Vector3(.6,.5,18),Color("d9c3a0"))
	var cover=Node3D.new();cover.name="Cover";root.add_child(cover)
	# Low rounded walls with painted caps: clear cover height for FPS reading.
	for spec in [[Vector3(-8,0,-3),Vector3(5,1.1,.7)],[Vector3(7,0,-5),Vector3(.7,1.1,4)],[Vector3(2,0,2.5),Vector3(4,1.1,.7)]]:
		var p:Vector3=spec[0];var s:Vector3=spec[1]
		S.rbox(cover,p+Vector3(0,s.y*.5,0),s,Color("f6f0e6"),Vector3.ZERO,.35)
		S.rbox(cover,p+Vector3(0,s.y+.06,0),s+Vector3(.12,.12-s.y,.12),Color("ff7a59"),Vector3.ZERO,.6)
	var props=Node3D.new();props.name="Props";root.add_child(props)
	for c in [[Vector3(-4,0,-6),Color("ffb347")],[Vector3(-3,0,-6.6),Color("5fb8ff")],[Vector3(-3.5,1.2,-6.3),Color("ffb347")]]:
		var p:Vector3=c[0]
		S.rbox(props,p+Vector3(0,.6,0),Vector3(1.2,1.2,1.2),c[1],Vector3(0,.2,0),.25)
		S.rbox(props,p+Vector3(0,.6,0),Vector3(1.26,.18,1.26),Color("fff4dc"),Vector3(0,.2,0),.4)
	for p in [Vector3(9,0,1),Vector3(9.9,0,1.6),Vector3(9.3,0,2.5)]:
		S.cyl(props,p+Vector3(0,.55,0),.42,1.1,Color("3fc4a0"))
		for h in [.2,.9]:S.cyl(props,p+Vector3(0,h,0),.44,.08,Color("2a8f78"))
		S.cyl(props,p+Vector3(0,1.12,0),.3,.04,Color("fff4dc"))
	# Lamp and bench give scale; the planters mark the courtyard zone.
	S.cyl(props,Vector3(-10,1.6,4),.07,3.2,Color("39405a"))
	S.ell(props,Vector3(-10,3.25,4),Vector3(.5,.35,.5),Color("fff1b0"))
	S.rbox(props,Vector3(-6,.45,6),Vector3(2.4,.18,.7),Color("c7844f"))
	for x in [-.9,.9]:S.rbox(props,Vector3(-6+x,.2,6),Vector3(.15,.4,.6),Color("39405a"))
	var foliage=Node3D.new();foliage.name="Foliage";root.add_child(foliage)
	for p in [Vector3(-12,0,-7),Vector3(12,0,-7),Vector3(-12,0,5),Vector3(12,0,6)]:
		S.cyl(foliage,p+Vector3(0,1.,0),.22,2.,Color("9a6a45"))
		S.ell(foliage,p+Vector3(0,2.6,0),Vector3(2.6,2.2,2.6),Color("69cf6a"))
		S.ell(foliage,p+Vector3(.7,3.2,.3),Vector3(1.6,1.4,1.6),Color("8be07c"))
		S.ell(foliage,p+Vector3(-.6,3.1,-.4),Vector3(1.5,1.3,1.5),Color("58b95c"))
	for p in [Vector3(4,0,6),Vector3(-1,0,-9)]:
		S.rbox(foliage,p+Vector3(0,.35,0),Vector3(1.8,.7,1.),Color("e07a5f"),Vector3.ZERO,.4)
		for k in range(4):S.ell(foliage,p+Vector3(-.6+k*.4,.85,0),Vector3(.5,.45,.5),Color("ff8fb1") if k%2==0 else Color("7ad97a"))
	# Building fronts in the distance: two districts with different palettes.
	var fronts=Node3D.new();fronts.name="Fronts";root.add_child(fronts)
	for i in range(5):
		var x=-12+i*6.;var c=[Color("8fc3ff"),Color("ffd27a"),Color("b7a5ff"),Color("7fe0c4"),Color("ffa98a")][i]
		S.rbox(fronts,Vector3(x,3,-12),Vector3(5.6,6+i%2*2,2),c,Vector3.ZERO,.12)
		S.rbox(fronts,Vector3(x,6.2+i%2*2,-12),Vector3(5.9,.35,2.3),Color("fff4dc"),Vector3.ZERO,.3)
		for wx in [-1.4,1.4]:
			for wy in [2.,4.2]:S.rbox(fronts,Vector3(x+wx,wy,-10.95),Vector3(1.1,1.2,.1),Color("3b4a6b"),Vector3.ZERO,.3)
		S.rbox(fronts,Vector3(x,1.1,-10.95),Vector3(1.2,2.2,.12),c.darkened(.35),Vector3.ZERO,.3)
	S.finish(root)
	return root
static func environment(parent:Node3D):
	var env=Environment.new();env.background_mode=Environment.BG_SKY
	var sky=Sky.new();var mat=ProceduralSkyMaterial.new()
	mat.sky_top_color=Color("5aa9ff");mat.sky_horizon_color=Color("cfe9ff");mat.ground_horizon_color=Color("cfe9ff");mat.ground_bottom_color=Color("9fc7e6");mat.sun_angle_max=20
	sky.sky_material=mat;env.sky=sky;env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("ffffff");env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true;env.fog_light_color=Color("d6ecff");env.fog_density=.006;env.fog_sky_affect=0.
	var world=WorldEnvironment.new();world.environment=env;parent.add_child(world)
