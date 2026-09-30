class_name GunModel
extends Node3D
## 1.4 weapon model built from a baked Toon Shooter (CC0) base
## (tools/bake_weapons.gd) plus a per-weapon look from GunLooks: scale,
## palette and small cartoon attachments. Markers: RightGrip, LeftGrip, Muzzle.
## Weapons are authored with the butt (or pistol grip) at the origin, muzzle -Z.
static var bases={}
# Hand handles per base (base-local metres, muzzle -Z), measured on the baked
# meshes with tools/probe_grip_shape.gd, tools/probe_support.gd and the side
# renders of tools/probe_grips.gd:
#  right: centre of the pistol grip (or stock wrist), "tilt" its lean (bottom
#         rearward, radians), "grip" half extents (x width, y along the grip,
#         z depth) and "round"; "trigger": where the index finger rests.
#  left:  centre of the handguard / pump (palm up under it, "fore" half
#         extents) or of a vertical grip ("left_style": "pistol").
#  sight: rear-sight point the camera lines up with when aiming without optics.
const HANDLES={
	"AK":{"right":Vector3(0,-.125,-.231),"tilt":.05,"grip":Vector3(.0215,.058,.04),"round":.015,"trigger":Vector3(0,-.054,-.298),
		# 1.4.2: support hand on the slim handguard ahead of the receiver face.
		"left":Vector3(0,.02,-.67),"fore":Vector3(.029,.045,.028),"fore_round":.02,"sight":Vector3(0,.12,-.36)},
	# No stock: held forward so the rear grip sits where a rifle's grip would.
	"SMG":{"frame_offset":Vector3(0,0,-.2),"right":Vector3(0,-.108,-.056),"tilt":.18,"grip":Vector3(.016,.058,.036),"round":.013,"trigger":Vector3(0,-.078,-.135),
		"left":Vector3(0,-.16,-.292),"left_style":"pistol","left_tilt":-.23,"fore":Vector3(.0195,.05,.05),"fore_round":.016,"sight":Vector3(0,.085,-.30)},
	"Pistol":{"right":Vector3(0,-.047,.001),"tilt":.2,"grip":Vector3(.011,.036,.024),"round":.009,"trigger":Vector3(0,-.03,-.045),"sight":Vector3(0,.055,0)},
	"Revolver":{"right":Vector3(0,-.055,.003),"tilt":.45,"grip":Vector3(.011,.032,.026),"round":.009,"trigger":Vector3(0,-.035,-.064),"sight":Vector3(0,.07,-.02)},
	"Revolver_Small":{"right":Vector3(0,-.067,-.008),"tilt":.36,"grip":Vector3(.014,.035,.028),"round":.011,"trigger":Vector3(0,-.042,-.079),"sight":Vector3(0,.07,-.02)},
	# 1.4.2: the firing hand at the front of the stock wrist (the web against the
	# receiver) and the support hand on the pump itself (measured on the model).
	"Shotgun":{"right":Vector3(0,-.05,-.262),"tilt":.36,"grip":Vector3(.029,.045,.03),"round":.02,"trigger":Vector3(0,-.095,-.38),
		"left":Vector3(0,-.045,-.84),"fore":Vector3(.0266,.0275,.06),"fore_round":.02,"sight":Vector3(0,.05,-.60)},
	"ShortCannon":{"right":Vector3(0,-.02,-.255),"tilt":.45,"grip":Vector3(.025,.04,.028),"round":.018,"trigger":Vector3(0,-.07,-.356),
		# 1.4.2: on the pump, not on the barrel tip (the fingers passed the muzzle).
		"left":Vector3(0,0,-.52),"fore":Vector3(.033,.031,.04),"fore_round":.025,"sight":Vector3(0,.05,-.45)},
	"Sniper":{"right":Vector3(0,-.115,-.258),"tilt":.47,"grip":Vector3(.014,.048,.039),"round":.012,"trigger":Vector3(0,-.07,-.346),
		"left":Vector3(0,.004,-.70),"fore":Vector3(.0184,.0326,.05),"fore_round":.016,"sight":Vector3(0,.15,-.45)},
	"Sniper_2":{"right":Vector3(0,-.11,-.264),"tilt":.40,"grip":Vector3(.0215,.048,.04),"round":.015,"trigger":Vector3(0,-.068,-.359),
		# 1.4.2: on the barrel ahead of the magazine (the palm used to reach back into it).
		"left":Vector3(0,.02,-.70),"fore":Vector3(.0219,.072,.03),"fore_round":.015,"sight":Vector3(0,.15,-.42)}}
# Scope glass of the baked sniper bases (base-local): [centre, facing, radius]
# of the ocular and the objective, just proud of the recessed faces. Measured
# with tools/probe_scopes.gd.
const SCOPES={
	"Sniper":[[Vector3(0,.0939,-.2752),Vector3(0,0,1),.034],[Vector3(0,.0950,-.6135),Vector3(0,-.385,-.923),.042]],
	"Sniper_2":[[Vector3(0,.1183,-.3055),Vector3(0,0,1),.032],[Vector3(0,.1210,-.5700),Vector3(0,-.379,-.9255),.044]]}
var spec={}
var look={}
var base:Node3D
var muzzle:Marker3D
var right_grip:Marker3D
var left_grip:Marker3D
var aim_point:Marker3D # rear sight / optic centre, lined up with the camera when aiming
var launcher=false # rocket launcher built by LauncherModels (visible rounds)
var rounds:Array=[] # Round<i> nodes of a launcher, front to back order of loading
var magazine:Node3D
var mag_rest=Transform3D.IDENTITY
var flash:Node3D
var outlined=false
# DUET: a second pistol in the left hand; shots alternate between the muzzles.
var dual_guns:Array=[]
var muzzles:Array=[]
var fire_side=0:
	set(value):
		fire_side=value
		if muzzles.size()>1:muzzle=muzzles[clampi(value,0,1)]
static func base_scene(name:String) -> PackedScene:
	if not bases.has(name):bases[name]=load("res://assets/weapons/"+name.to_lower()+".scn")
	return bases[name]
func build(w:Dictionary,ink:bool=false):
	spec=w;outlined=ink;look=GunLooks.look(w)
	set_meta("wid",GripField.id_of(w))
	launcher=look.has("launcher")
	base=GunLooks.build_tool(look.tool) if look.has("tool") else LauncherModels.build(look.launcher) if launcher else base_scene(look.base).instantiate()
	add_child(base)
	base.scale=Vector3.ONE*float(look.get("scale",1.))
	muzzle=base.get_node("Muzzle");right_grip=base.get_node("RightGrip");left_grip=base.get_node("LeftGrip")
	var pistol=GunLooks.hold_kind(w)=="pistol"
	if base.has_node("AimPoint"):aim_point=base.get_node("AimPoint")
	else:
		aim_point=Marker3D.new();aim_point.name="AimPoint";base.add_child(aim_point)
		aim_point.position=Vector3(0,muzzle.position.y+(.05 if pistol else .07),right_grip.position.z-(0. if pistol else .10))
	var shapes=place_handles(base,look)
	if launcher:
		for i in range(int(base.get_meta("rounds",0))):rounds.append(base.get_node("Round%d"%i))
	magazine=base.get_node_or_null("Magazine")
	if magazine:mag_rest=magazine.transform
	for mesh in base.find_children("*","MeshInstance3D",true,false):paint(mesh)
	if w.get("laser",false) and is_instance_valid(magazine):batteries()
	glaze(base,look)
	GunLooks.attach(self,look)
	# A dot or scope on top replaces the iron rear sight as the aiming point.
	for kind in look.get("attach",[]):
		if kind=="dot":aim_point.position=Vector3(0,muzzle.position.y+.075,right_grip.position.z-.115)
		elif kind=="scope":aim_point.position=Vector3(0,muzzle.position.y+.075,right_grip.position.z-.09)
	muzzles=[muzzle];dual_guns=[base]
	# Launchers have vertical foregrips (both hands make a fist), as does the
	# SMG whose support hand holds the magazine.
	var h:Dictionary=HANDLES.get(str(look.get("base","")),{})
	set_meta("grip_styles",{"R":"pistol","L":str(h.get("left_style","pistol" if launcher else "support"))})
	# Code-built tools may name their own hand styles (the TETHER pad).
	if base.has_meta("grip_styles"):set_meta("grip_styles",base.get_meta("grip_styles"))
	# 1.4.2: pistols are held in both hands (as in most shooters): the support
	# hand closes round the firing hand, over its fingers at the front and on
	# the left of the grip, a little lower so its index sits under the guard.
	if pistol and not w.get("dual",false) and shapes.has("R"):
		var k=1./maxf(.01,base.scale.x);var r:Dictionary=shapes.R
		left_grip.transform=right_grip.transform*Transform3D(Basis.IDENTITY,Vector3(0,-.014,.004)*k)
		shapes.L={"half":Vector3(r.half)+Vector3(.02,.004,.017)*k,"round":float(r.get("round",.012))+.008*k,"cup":true}
		set_meta("grip_styles",{"R":"pistol","L":"pistol"})
	set_meta("grip_shapes",shapes)
	# Third person: where the weapon sits in the shoulder frame (HeroCharacter).
	if h.has("frame_offset"):set_meta("frame_offset",h.frame_offset*base.scale.x)
	if w.get("dual",false):
		var second:Node3D=base_scene(look.base).instantiate();add_child(second);second.name="LeftPistol"
		second.scale=base.scale
		for mesh in second.find_children("*","MeshInstance3D",true,false):paint(mesh)
		var pair=place_handles(second,look)
		left_grip=second.get_node("RightGrip");muzzles.append(second.get_node("Muzzle"));dual_guns.append(second)
		set_meta("grip_styles",{"R":"pistol","L":"pistol"})
		set_meta("grip_shapes",{"R":shapes.get("R",{}),"L":pair.get("R",{})})
		set_pair_spacing(PAIR_SPACING)
	for m in muzzles:
		var f=Node3D.new();f.name="MuzzleFlash";m.add_child(f)
	flash=muzzle.get_node("MuzzleFlash")
	if w.get("laser",false):
		# Heat gauge sits on the right side above the grip (LaserGauge lays itself out from there).
		var mount=Node3D.new();mount.name="GaugeMount";mount.position=right_grip.position*base.scale+Vector3(-.03,.02,.06);add_child(mount)
		var gauge=LaserGauge.new();gauge.name="HeatGauge";mount.add_child(gauge)
	name="Gun_"+str(w.get("name","?"))
func grip(side:String) -> Node3D:return right_grip if side=="R" else left_grip
## The laser rifle runs on two D-size cells (as in 1.3): the box magazine of
## the base model is replaced by a pair of yellow cells with red terminals on a
## latch plate. They are the magazine node, so the reload swaps them.
# Transform of `node` in the space of its ancestor (works outside the tree).
static func relative(node:Node3D,ancestor:Node3D) -> Transform3D:
	var xf=Transform3D.IDENTITY;var n:Node=node
	while n!=null and n!=ancestor:
		if n is Node3D:xf=(n as Node3D).transform*xf
		n=n.get_parent()
	return xf
const CELL_BODY=Color("efd447")
const CELL_CAP=Color("e34d3b")
const CELL_BAND=Color("312e26")
func batteries():
	var box=AABB();var first=true
	for m in magazine.find_children("*","MeshInstance3D",true,false)+([magazine] if magazine is MeshInstance3D else []):
		var b:AABB=GunModel.relative(m,magazine)*m.get_aabb()
		box=b if first else box.merge(b);first=false
		m.visible=false if m!=magazine else true
	if magazine is MeshInstance3D:magazine.mesh=null
	# Base units: cells sized in metres, divided by the base scale.
	var k=1./maxf(.01,base.scale.x)
	var radius=.021*k;var height=.085*k
	var top=box.end.y if not first else 0.
	var centre_z=box.get_center().z if not first else 0.
	var pack=Node3D.new();pack.name="Cells";magazine.add_child(pack)
	for side in [-1,1]:
		var x=side*radius*1.08
		MeshFactory.cylinder(pack,Vector3(x,top-height*.5,centre_z),radius,height,CELL_BODY,Vector3.ZERO,-1.,14)
		MeshFactory.cylinder(pack,Vector3(x,top-height*.62,centre_z),radius*1.01,height*.16,CELL_BAND,Vector3.ZERO,-1.,14)
		MeshFactory.cylinder(pack,Vector3(x,top-height-.004*k,centre_z),radius*.45,.008*k,CELL_CAP,Vector3.ZERO,-1.,10)
	MeshFactory.box(pack,Vector3(0,top-height*.08,centre_z),Vector3(radius*4.3,.012*k,radius*2.2),Color("2e333d"),Vector3.ZERO,.4)
	MeshFactory.merge_children(pack) # bakes each part's colour into vertex colours
	for mesh in pack.find_children("*","MeshInstance3D",true,false):
		mesh.material_override=HeroStyle.toon_material(outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
# DUET: distance between the two pistols (base-local x), centred on the gun
# node's origin line of the right pistol.
const PAIR_SPACING=.26
func set_pair_spacing(width:float):
	if dual_guns.size()<2:return
	dual_guns[1].position=Vector3(-width,0,.02)
# Moves a base's grip markers onto the measured handles and returns the grip
# shapes per hand (handle frame, base units): half extents, rounding and the
# trigger point. Code-built bases (launchers, tools) carry their own shapes.
static func place_handles(node:Node3D,l:Dictionary) -> Dictionary:
	var right:Marker3D=node.get_node("RightGrip");var left:Marker3D=node.get_node("LeftGrip")
	var shapes={}
	var h:Dictionary=HANDLES.get(str(l.get("base","")),{})
	if node.has_meta("grip_shapes"):
		for side in node.get_meta("grip_shapes"):
			var shape:Dictionary=node.get_meta("grip_shapes")[side].duplicate()
			var marker:Marker3D=right if side=="R" else left
			if shape.has("trigger"):shape.trigger=marker.transform.affine_inverse()*shape.trigger
			shapes[side]=shape
		return shapes
	if h.has("right"):
		right.position=h.right;right.rotation=Vector3(-float(h.get("tilt",0.)),0,0)
		shapes.R={"half":h.get("grip",Vector3(.016,.05,.03)),"round":float(h.get("round",.012))}
		if h.has("trigger"):shapes.R.trigger=right.transform.affine_inverse()*h.trigger
	if h.has("left"):
		left.position=h.left;left.rotation=Vector3(-float(h.get("left_tilt",0.)),0,0)
		shapes.L={"half":h.get("fore",Vector3(.024,.024,.05)),"round":float(h.get("fore_round",.02))}
	if node.has_node("AimPoint") and h.has("sight"):node.get_node("AimPoint").position=h.sight
	return shapes
## Launchers: show `count` loaded rockets; while reloading (`loading` 0..1) the
## support hand brings the next rocket up behind the tube and pushes it, nose
## first, into the open rear end.
const LOAD_SHOW=.30 # the rocket appears in the hand
const LOAD_ALIGN=.52 # nose at the rear opening
const LOAD_PUSH=.80 # pushed home
func set_rounds(count:int,loading:float=-1.):
	if not launcher:return
	for i in range(rounds.size()):
		var round:Node3D=rounds[i]
		if i<count:round.visible=true;round.position=round.get_meta("seat")
		elif i==count and loading>=LOAD_SHOW:round.visible=true;round.position=loading_round_local(i,loading)
		else:round.visible=false
# The rocket being loaded, in the launcher's own (unscaled) space.
func loading_round_local(index:int,t:float) -> Vector3:
	var round:Node3D=rounds[index];var seat:Vector3=round.get_meta("seat");var rear=float(base.get_meta("rear",0.))
	if t>=LOAD_PUSH:return seat
	var fetch=Vector3(seat.x-.17,seat.y-.24,rear+.16)
	var aligned=Vector3(seat.x,seat.y,rear+float(round.get_meta("front"))+.015)
	var home=Vector3(seat.x,seat.y,rear-float(round.get_meta("back"))-.01)
	if t<LOAD_ALIGN:return fetch.lerp(aligned,smoothstep(LOAD_SHOW,LOAD_ALIGN,t))
	return aligned.lerp(home,smoothstep(LOAD_ALIGN,LOAD_PUSH,t))
# The same point in the gun node's space.
func loading_round_position(count:int,t:float) -> Vector3:
	if not launcher or count>=rounds.size():return Vector3.ZERO
	return loading_round_local(count,t)*base.scale
# Size of the rocket being loaded (launcher units).
func loading_round(count:int) -> Dictionary:
	if not launcher or rounds.is_empty():return {}
	var round:Node3D=rounds[clampi(count,0,rounds.size()-1)]
	return {"radius":float(round.get_meta("radius",.04)),"length":float(round.get_meta("length",.3))}
# Where the support hand holds the rocket (gun node space): on its axis in the
# rear half, never closer to the tube than a hand's width behind the opening,
# so the rocket slides through the palm for the last push.
func loading_grip(count:int,t:float) -> Vector3:
	if not launcher or rounds.is_empty():return Vector3.ZERO
	var index=clampi(count,0,rounds.size()-1)
	var round:Node3D=rounds[index];var rear=float(base.get_meta("rear",0.))
	var point=loading_round_local(index,minf(t,LOAD_PUSH-.001))+Vector3(0,0,float(round.get_meta("back"))*.55)
	point.z=maxf(point.z,rear+.06)
	return point*base.scale
# Blue glass on both ends of a baked scope.
static func glaze(node:Node3D,l:Dictionary):
	var faces:Array=SCOPES.get(str(l.get("base","")),[])
	for i in range(faces.size()):
		ScopeVisual.lens_disc(node,faces[i][0],faces[i][1],faces[i][2],"OcularGlass" if i==0 else "ObjectiveGlass")
func paint(mesh:MeshInstance3D):
	if look.has("tool") or launcher:
		mesh.material_override=HeroStyle.toon_material(outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;return
	var palette:Dictionary=look.get("palette",{})
	for s in range(mesh.mesh.get_surface_count()):
		var source:Material=mesh.mesh.surface_get_material(s)
		var key=source.resource_name if source else ""
		var color:Color=palette.get(key,source.albedo_color if source is BaseMaterial3D else Color.GRAY)
		mesh.set_surface_override_material(s,HeroStyle.tinted(color,outlined,.25))
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
## Reload: magazine out (drop/slide down), in, seat. `t` is 0..1 progress, -1 idle.
func animate_reload(t:float,recoil:float=0.,_shot_age:float=10.):
	if not is_instance_valid(magazine):return
	if t<0.:magazine.transform=mag_rest;magazine.visible=true;return
	var out=smoothstep(.08,.30,t)*(1.-smoothstep(.55,.80,t))
	magazine.transform=mag_rest.translated_local(Vector3(0,-.22*out,.03*out))
	# The magazine stays in the support hand through the swap (old one out, new one in).
	magazine.visible=true
