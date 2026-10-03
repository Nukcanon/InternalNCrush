class_name MeleeVisual
extends Node3D
## 1.4 melee tools: Toon Shooter (CC0) knife or a cartoon wrench, authored with
## the handle at the origin and the blade / head along +Y. In first person
## `pose()` swings the pivot in camera space and the hero's arm is IK'd onto the
## handle marker (hammer grip, blade forward); in third person the tool rides the
## right hand bone while the hero plays its slash clip.
var tool=false
# Roll about the blade so the edge faces forward in the first-person rest
# pose. Knife_1's edge is its -X side (the blade is 4 cm wide in x, 1 mm thick
# there and 8 mm at the serrated +x spine); in the wrist frame the edge then
# points (0,-cos roll, sin roll), and with the rest pose's wrist basis
# (Actor: fist along -FP_FOREARM_MELEE, blade on the thumb side, up and
# forward) a roll of 2.67 rad puts the edge within 15 degrees of straight ahead.
const KNIFE_ROLL=2.67
# Hand-bone frame (+Y fingers, -Z palm): the hollow of the closed fist, where the
# handle sits inside the curled fingers (HeroIK fist curl: knuckles at y .15,
# curled tips back at y .10, middle joints at z -.04).
const FIST_HOLLOW=Vector3(0,.125,-.024)
var in_hand=false # third person: mounted on the hand bone, no swing pose
var pivot:Node3D
var palm:Marker3D
func build(wrench:bool,_role:int,first_person:bool):
	tool=wrench;in_hand=not first_person;pivot=Node3D.new();pivot.name="Pivot";add_child(pivot)
	var model=Node3D.new();model.name="Model";pivot.add_child(model)
	if tool:
		# 1.4.5: a pipe wrench. Red I-section handle, a steel shank rising from
		# it with the knurled adjusting nut, the heel jaw on the shank and the
		# tall hook jaw whose overhang closes the C toward the -X side; both
		# jaws carry teeth.
		var M=MeshFactory;var red=Color("d9483b");var steel=Color("9aa6b3");var ink=Color("2a303a");var dark_steel=Color("6c7681")
		M.box(model,Vector3(0,-.03,0),Vector3(.034,.24,.026),red,Vector3.ZERO,.5)
		for z in [-.014,.014]:M.box(model,Vector3(0,-.03,z),Vector3(.04,.22,.006),red,Vector3.ZERO,.4)
		M.box(model,Vector3(0,-.155,0),Vector3(.044,.02,.032),ink,Vector3.ZERO,.5)
		# Shank and adjusting nut.
		M.box(model,Vector3(.01,.125,0),Vector3(.026,.09,.02),steel,Vector3.ZERO,.3)
		M.cylinder(model,Vector3(.01,.105,0),.03,.028,ink,Vector3.ZERO,-1.,12)
		for k in range(8):
			var a=k*PI/4.
			M.box(model,Vector3(.01+cos(a)*.03,.105,sin(a)*.03),Vector3(.006,.022,.006),dark_steel,Vector3(0,-a,0),.2)
		# Heel jaw (on the shank, teeth on top).
		M.box(model,Vector3(-.012,.175,0),Vector3(.05,.034,.03),steel,Vector3.ZERO,.3)
		for k in range(4):M.box(model,Vector3(-.03+k*.01,.195,0),Vector3(.006,.008,.028),dark_steel,Vector3.ZERO,.2)
		# Hook jaw: tall bar on the +X side, its overhang reaching over to -X.
		M.box(model,Vector3(.028,.22,0),Vector3(.026,.12,.03),steel,Vector3.ZERO,.3)
		M.box(model,Vector3(-.005,.272,0),Vector3(.092,.03,.03),steel,Vector3.ZERO,.35)
		for k in range(5):M.box(model,Vector3(-.045+k*.011,.254,0),Vector3(.006,.008,.028),dark_steel,Vector3.ZERO,.2)
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
	# Handle marker: -Z of the marker runs along the blade (+Y of the model).
	palm=Marker3D.new();palm.name="RightGrip";pivot.add_child(palm);palm.position=Vector3(0,-.02 if tool else .01,0);palm.rotation=Vector3(PI/2,0,0)
	set_meta("grip_styles",{"R":"knife"})
	# 1.4.4: first person too rides the hand bone (the tool never parts from
	# the fist); the arm itself is swung (swing_wrist).
	in_hand=true
	# Hand-bone mount (wrist frame: +Y fingers, -Z palm, -X thumb): the handle
	# sits in the palm and the blade leaves the fist on the thumb side.
	# Round 4: the knife is rolled a quarter turn about the blade so its cutting
	# edge faces forward (away from the player), the spine back toward the eye.
	pivot.basis=Basis(Vector3(0,0,1),PI*.5)*(Basis(Vector3(0,1,0),KNIFE_ROLL) if not tool else Basis.IDENTITY);pivot.position=FIST_HOLLOW
	pose(-1.)
func grip(_side:String) -> Node3D:return palm
## The handle as the fist closes on it (HeroIK.fingers_round): its centre in
## the wrist bone's space and half extents (radius, half length, radius) in
## the same units.
func handle_shape() -> Dictionary:
	var shape={"centre":FIST_HOLLOW,"half":Vector3(.02,.11,.015) if tool else Vector3(.012,.055,.011),"round":.012 if tool else .011}
	if tool:shape.close={"Ring":Vector2(1.,.06),"Pinky":Vector2(1.,.1)} # (1.5.2: closed round the long handle like a fist)
	return shape
## 1.4.4 first-person swing: the wrist's place in camera space (right-handed;
## x mirrors for a left-handed player) over the swing. The hand keeps its
## orientation from the arm (HeroCharacter solves the arm straight to it), so
## arm, fist and blade turn together: a wind-up back and up beside the head,
## a diagonal cut down across the view, then back to a low ready.
static func swing_wrist(age:float,hand:float=1.) -> Vector3:
	var rest=Vector3(.26,-.26,-.44);var wind=Vector3(.40,.0,-.34);var finish=Vector3(-.10,-.36,-.62)
	var p=rest
	if age>=0. and age<MeleeCombat.DURATION:
		if age<MeleeCombat.CONTACT_START:p=rest.lerp(wind,smoothstep(0.,MeleeCombat.CONTACT_START,age))
		elif age<=MeleeCombat.CONTACT_END:p=wind.lerp(finish,clampf((age-MeleeCombat.CONTACT_START)/(MeleeCombat.CONTACT_END-MeleeCombat.CONTACT_START),0.,1.))
		else:p=finish.lerp(rest,smoothstep(MeleeCombat.CONTACT_END,MeleeCombat.DURATION,age))
	p.x*=hand
	return p
## 1.5.4 (the user's clip of a Counter-Strike knife): first-person knife keys over one swing
## (seconds from its start; it spans the swing interval). Camera space, right-handed:
## the wrist, the forearm (wrist -> elbow) and the blade's way out of the fist. At rest the
## fist sits low right with the blade tipped up and to the left, the free fist low left of
## the middle. The slash whips the arm across to the left almost at once, sweeps it back
## through the middle and down out of the view at the right, then the knife rises back
## from below. The free fist drops out of the view for the swing and comes back after.
const KNIFE_KEYS=[
	[0.,Vector3(.23,-.35,-.45),Vector3(.35,-.35,.87),Vector3(-.84,.47,-.28)],
	[.035,Vector3(-.15,-.21,-.58),Vector3(.62,-.22,.76),Vector3(-.95,.25,-.15)],
	[.10,Vector3(.05,-.24,-.61),Vector3(.48,-.30,.82),Vector3(-.85,.40,-.30)],
	[.17,Vector3(.30,-.37,-.50),Vector3(.32,-.45,.83),Vector3(-.50,.55,-.65)],
	[.24,Vector3(.36,-.68,-.36),Vector3(.25,-.60,.76),Vector3(-.25,.45,-.85)],
	[.48,Vector3(.36,-.68,-.36),Vector3(.25,-.60,.76),Vector3(-.25,.45,-.85)],
	[.62,Vector3(.27,-.44,-.42),Vector3(.33,-.42,.84),Vector3(-.45,.75,-.48)],
	[.74,Vector3(.23,-.35,-.45),Vector3(.35,-.35,.87),Vector3(-.84,.47,-.28)]]
const KNIFE_FREE_REST=Vector3(-.22,-.39,-.46) # (1.5.4, the user: both fists moved left so their middle is the view's centre)
const KNIFE_FREE_DOWN=Vector3(-.12,-.66,-.34)
const KNIFE_SWING_TIME=.74
static func knife_swing(age:float) -> Dictionary:
	var k=KNIFE_KEYS;var at=k[0]
	if age>=0. and age<KNIFE_SWING_TIME:
		for i in range(k.size()-1):
			if age<=float(k[i+1][0]):
				var t=clampf((age-float(k[i][0]))/maxf(.001,float(k[i+1][0])-float(k[i][0])),0.,1.)
				if i>0:t=smoothstep(0.,1.,t) # (the first whip is linear: it is that fast)
				at=[age,Vector3(k[i][1]).lerp(k[i+1][1],t),Vector3(k[i][2]).normalized().slerp(Vector3(k[i+1][2]).normalized(),t),Vector3(k[i][3]).normalized().slerp(Vector3(k[i+1][3]).normalized(),t)]
				break
	# the free fist: down within 0.06 s, back over the last part of the return
	var down=0.
	if age>=0. and age<KNIFE_SWING_TIME:down=smoothstep(0.,.06,age)*(1.-smoothstep(.56,KNIFE_SWING_TIME,age))
	return {"wrist":at[1],"forearm":at[2],"blade":at[3],"free":KNIFE_FREE_REST.lerp(KNIFE_FREE_DOWN,down),"free_down":down}
func pose(age:float):
	if not is_instance_valid(pivot) or in_hand:return
	# Blade forward at rest; a wind-up back and up, then a downward diagonal cut
	# across the view. Positions stay within the short cartoon arm's reach from
	# the view body's shoulder. Parent mirroring supplies the left-hand version.
	var rest=Vector3(.12,-.08,-.14);var wind=Vector3(.26,.14,-.08);var finish=Vector3(-.18,-.20,-.28)
	var rest_rot=Vector3(-1.25,.15,-.15);var wind_rot=Vector3(-.55,-.45,-.55);var finish_rot=Vector3(-2.05,.5,1.0)
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
			pivot.position=finish.lerp(rest,t)+Vector3(0,-.06*sin(t*PI),.08*sin(t*PI));pivot.rotation=finish_rot.lerp(rest_rot,t)
