class_name MeleeVisual
extends Node3D
## 1.4 melee tools: Toon Shooter (CC0) knife or a cartoon wrench. In first
## person `pose()` swings the pivot in camera space and the hero's forearm is
## IK'd onto `palm`; in third person the tool rides the right hand bone while the
## hero plays its slash clip.
var tool=false
var pivot:Node3D
var palm:Marker3D
func build(wrench:bool,_role:int,first_person:bool):
	tool=wrench;pivot=Node3D.new();pivot.name="Pivot";add_child(pivot)
	var model=Node3D.new();model.name="Model";pivot.add_child(model)
	if tool:
		var M=MeshFactory;var red=Color("d9483b");var steel=Color("9aa6b3");var ink=Color("2a303a")
		M.box(model,Vector3(0,-.02,0),Vector3(.04,.22,.03),red,Vector3.ZERO,.6)
		M.box(model,Vector3(0,.13,0),Vector3(.1,.07,.04),steel,Vector3.ZERO,.5)
		M.box(model,Vector3(-.035,.19,0),Vector3(.03,.1,.035),steel,Vector3.ZERO,.4)
		M.box(model,Vector3(.03,.18,0),Vector3(.03,.07,.035),steel,Vector3.ZERO,.4)
		M.cylinder(model,Vector3(0,.11,.0),.022,.05,ink,Vector3(PI/2,0,0),-1.,10)
		M.box(model,Vector3(0,-.13,0),Vector3(.05,.03,.035),ink,Vector3.ZERO,.5)
		MeshFactory.merge_children(model)
		for mesh in model.get_children():
			if mesh is MeshInstance3D:mesh.material_override=HeroStyle.toon_material(false,.3)
	else:
		var knife:Node3D=GunModel.base_scene("Knife_1").instantiate();model.add_child(knife)
		var palette={"Grey":Color("aeb8c4"),"LightGrey":Color("dfe6ec"),"Wood":Color("b0763c"),"DarkWood":Color("6f4a2a")}
		for mesh in knife.find_children("*","MeshInstance3D",true,false):
			for s in range(mesh.mesh.get_surface_count()):
				var source:Material=mesh.mesh.surface_get_material(s)
				mesh.set_surface_override_material(s,HeroStyle.tinted(palette.get(source.resource_name if source else "",Color("8a939e")),false,.3))
	for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	palm=Marker3D.new();palm.name="RightGrip";pivot.add_child(palm);palm.position=Vector3(.02,-.04,.03)
	if not first_person:
		# Hand-bone mount: blade along the fist, edge forward.
		pivot.rotation=Vector3(PI*.5,0,0);pivot.position=Vector3(0,.07,.02)
	pose(-1.)
func grip(_side:String) -> Node3D:return palm
func pose(age:float):
	if not is_instance_valid(pivot) or pivot.rotation.x==PI*.5:return
	# Right-handed downward diagonal cut; parent mirroring supplies the left-hand version.
	var rest=Vector3(.16,-.08,-.08);var wind=Vector3(.38,.24,-.16);var finish=Vector3(-.40,-.30,-.42)
	var rest_rot=Vector3(-.35,0,-.20);var wind_rot=Vector3(.15,-.30,-.65);var finish_rot=Vector3(-1.1,.45,1.35)
	pivot.position=rest;pivot.rotation=rest_rot
	if age>=0. and age<MeleeCombat.DURATION:
		if age<MeleeCombat.CONTACT_START:
			var t=smoothstep(0.,MeleeCombat.CONTACT_START,age)
			pivot.position=rest.lerp(wind,t);pivot.rotation=rest_rot.lerp(wind_rot,t)
		elif age<=MeleeCombat.CONTACT_END:
			var t=clampf((age-MeleeCombat.CONTACT_START)/(MeleeCombat.CONTACT_END-MeleeCombat.CONTACT_START),0.,1.)
			pivot.position=wind.lerp(finish,t);pivot.rotation=wind_rot.lerp(finish_rot,t)
		else:
			var t=smoothstep(MeleeCombat.CONTACT_END,MeleeCombat.DURATION,age)
			pivot.position=finish.lerp(rest,t)+Vector3(0,-.10*sin(t*PI),.13*sin(t*PI));pivot.rotation=finish_rot.lerp(rest_rot,t)
