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
# Straight stocks (no pistol grip): shotguns and FOLD.
const STRAIGHT_STOCKS=["Shotgun","ShortCannon"]
func straight_wrist() -> bool:return straight_look(look)
# (a look with its own pistol grip, e.g. MENDER, is held by that grip)
static func straight_look(l:Dictionary) -> bool:return str(l.get("base","")) in STRAIGHT_STOCKS and not l.get("attach",[]).has("pistolgrip")
const HANDLES={
	"AK":{"right":Vector3(0,-.14,-.231),"tilt":.05,"index":[.12,.025],"grip":Vector3(.0215,.058,.04),"round":.015,"trigger":Vector3(0,-.054,-.298),
		# 1.4.2: no handguard on this base (only a bare barrel ahead of the
		# receiver), so the support hand closes round the upper magazine, which
		# leans forward 25 degrees. "front": where attachments hang (old grip).
		"left":Vector3(-.0025,-.17,-.452),"left_style":"pistol","left_tilt":-.43,"fore":Vector3(.0245,.05,.036),"fore_round":.012,
		"front":Vector3(0,.02,-.67),"sight":Vector3(0,.12,-.36)},
	# No stock: held forward so the rear grip sits where a rifle's grip would.
	"SMG":{"frame_offset":Vector3(0,0,-.2),"right":Vector3(0,-.123,-.056),"tilt":.18,"grip":Vector3(.016,.058,.036),"round":.013,"trigger":Vector3(0,-.078,-.135),
		"left":Vector3(0,-.16,-.292),"left_style":"pistol","left_tilt":-.23,"fore":Vector3(.0195,.05,.05),"fore_round":.016,"sight":Vector3(0,.085,-.30)},
	"Pistol":{"right":Vector3(0,-.062,.001),"tilt":.2,"grip":Vector3(.011,.036,.024),"round":.009,"trigger":Vector3(0,-.03,-.045),"sight":Vector3(0,.055,0)},
	"Revolver":{"right":Vector3(0,-.055,.003),"tilt":.45,"grip":Vector3(.011,.032,.026),"round":.009,"trigger":Vector3(0,-.035,-.064),"sight":Vector3(0,.07,-.02),"gate":Vector3(-.024,.018,-.018)},
	"Revolver_Small":{"right":Vector3(0,-.067,-.008),"tilt":.36,"grip":Vector3(.014,.035,.028),"round":.011,"trigger":Vector3(0,-.042,-.079),"sight":Vector3(0,.07,-.02),"gate":Vector3(-.024,.016,-.015)},
	# 1.4.2: the firing hand at the front of the stock wrist (the web against the
	# receiver) and the support hand on the pump itself (measured on the model).
	# 1.4.5: these two have straight stocks (no pistol grip): the firing hand
	# closes round the stock wrist leaning back with it (tilt .5; laid fully
	# along the stock the index finger could not reach the trigger), the arm
	# coming in from the side (Actor.fp_follow_for, STRAIGHT_STOCKS).
	"Shotgun":{"right":Vector3(0,-.02,-.27),"tilt":.5,"grip":Vector3(.029,.045,.03),"round":.02,"trigger":Vector3(0,-.095,-.38),
		# "port": the loading port under the receiver just ahead of the trigger
		# guard (shells went into the guard before).
		"left":Vector3(0,-.045,-.84),"fore":Vector3(.0266,.0275,.06),"fore_round":.02,"sight":Vector3(0,.05,-.60),"port":Vector3(0,-.085,-.50)},
	"ShortCannon":{"right":Vector3(0,-.02,-.28),"tilt":.5,"grip":Vector3(.025,.04,.028),"round":.018,"trigger":Vector3(0,-.07,-.356),
		# 1.4.2: on the pump, not on the barrel tip (the fingers passed the muzzle).
		"left":Vector3(-.007,-.008,-.485),"fore":Vector3(.034,.031,.04),"fore_round":.025,"sight":Vector3(0,.05,-.45),"breech":Vector3(0,.03,-.56)},
	"Sniper":{"right":Vector3(0,-.115,-.258),"tilt":.33,"grip":Vector3(.014,.048,.039),"round":.012,"trigger":Vector3(0,-.07,-.346),
		"left":Vector3(0,.004,-.70),"fore":Vector3(.0184,.0326,.05),"fore_round":.016,"sight":Vector3(0,.15,-.45)},
	"Sniper_2":{"right":Vector3(0,-.11,-.264),"tilt":.30,"grip":Vector3(.0215,.048,.04),"round":.015,"trigger":Vector3(0,-.068,-.359),
		# 1.4.2: the bare barrel ahead of the receiver gets a forend (GunLooks
		# "handguard", z -.648 to -.80) and the support hand holds that, not the
		# barrel; the curved magazine is too deep for a hand to close round.
		"left":Vector3(0,.011,-.722),"fore":Vector3(.028,.041,.05),"fore_round":.016,"sight":Vector3(0,.15,-.42),
		"handguard":[-.648,-.80,-.03,.052,.028]}}
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
var mag_height=.2 # gun-node space (see build)
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
# 1.4.4 round 6: the baked bases carry a deformation (tools/bake_weapons.gd:
# the pistol grip stretched down from its top, everything ahead of it drawn
# out a little), stored as the scene root's "deform" meta. HANDLES and SCOPES
# were measured on the undeformed bake, so every coordinate taken from them
# goes through the same mapping.
static var deforms={}
static func deform_of(name:String) -> Dictionary:
	if not deforms.has(name):
		var d={}
		if ResourceLoader.exists("res://assets/weapons/"+name.to_lower()+".scn"):
			var node:Node=base_scene(name).instantiate()
			if node.has_meta("deform"):d=node.get_meta("deform")
			node.free()
		deforms[name]=d
	return deforms[name]
static func deform_point(d:Dictionary,p:Vector3) -> Vector3:
	if d.is_empty():return p
	if float(d.grip)!=1. and p.y<float(d.y_top) and p.z>=float(d.z0) and p.z<=float(d.z1):p.y=float(d.y_top)+(p.y-float(d.y_top))*float(d.grip)
	if float(d.barrel)!=1. and p.z<float(d.z_grip):p.z=float(d.z_grip)+(p.z-float(d.z_grip))*float(d.barrel)
	return p
static var handle_cache={}
static func handles(name:String) -> Dictionary:
	if handle_cache.has(name):return handle_cache[name]
	var h:Dictionary=HANDLES.get(name,{}).duplicate(true)
	var d=deform_of(name)
	if not d.is_empty() and not h.is_empty():
		for key in ["right","left","trigger","sight","port","breech","gate","front"]:
			if h.has(key):h[key]=deform_point(d,Vector3(h[key]))
		if h.has("grip"):h.grip=Vector3(h.grip)*Vector3(1.,float(d.grip) if float(d.y_top)<INF else 1.,1.)
		if h.has("handguard"):
			var hg:Array=h.handguard.duplicate()
			for i in range(2):hg[i]=deform_point(d,Vector3(0,0,float(hg[i]))).z
			h.handguard=hg
	handle_cache[name]=h
	return h
static func scopes(name:String) -> Array:
	var faces:Array=SCOPES.get(name,[]).duplicate(true);var d=deform_of(name)
	for f in faces:f[0]=deform_point(d,Vector3(f[0]))
	return faces
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
	if magazine:
		mag_rest=magazine.transform
		# Height of the magazine (gun-node space): the reload pulls it out by
		# its own length, so a pistol's short magazine clears its grip while a
		# rifle's long one travels further (1.4.5).
		var box=AABB()
		for m in magazine.find_children("*","MeshInstance3D",true,false)+([magazine] if magazine is MeshInstance3D else []):
			if m.mesh==null:continue
			var local:AABB=relative(m,magazine)*m.get_aabb()
			box=local if box.size==Vector3.ZERO else box.merge(local)
		mag_height=maxf(.03,box.size.y*base.scale.y)
	split_pump()
	for mesh in base.find_children("*","MeshInstance3D",true,false):paint(mesh)
	double_sided_magazine()
	if w.get("laser",false) and is_instance_valid(magazine) and not look.has("tool"):batteries()
	glaze(base,look)
	GunLooks.attach(self,look)
	# A dot or scope on top replaces the iron rear sight as the aiming point.
	for kind in look.get("attach",[]):
		if kind=="dot":aim_point.position=Vector3(0,muzzle.position.y+.075,right_grip.position.z-.115)
		elif kind=="scope":aim_point.position=Vector3(0,muzzle.position.y+.075,right_grip.position.z-.09)
	muzzles=[muzzle];dual_guns=[base]
	# Launchers have vertical foregrips (both hands make a fist), as does the
	# SMG whose support hand holds the magazine.
	var h:Dictionary=handles(str(look.get("base","")))
	set_meta("grip_styles",{"R":"pistol","L":str(h.get("left_style","pistol" if launcher else "support"))})
	# Code-built tools may name their own hand styles (the TETHER pad).
	if base.has_meta("grip_styles"):set_meta("grip_styles",base.get_meta("grip_styles"))
	# 1.4.2: pistols are held in both hands (as in most shooters): the support
	# hand closes round the firing hand, over its fingers at the front and on
	# the left of the grip, a little lower so its index sits under the guard.
	if pistol and not w.get("dual",false) and shapes.has("R"):
		var k=1./maxf(.01,base.scale.x);var r:Dictionary=shapes.R
		# 1.4.4: the cup is the grip plus the firing hand round it (its fingers
		# a finger deep at the front and past the left side, the palm heel at
		# the back), so the support hand closes over the fingers, not through them.
		left_grip.transform=right_grip.transform*Transform3D(Basis.IDENTITY,Vector3(0,-.024,-.006)*k)
		shapes.L={"half":Vector3(r.half)+Vector3(.026,.012,.032)*k,"round":float(r.get("round",.012))+.012*k,"cup":true}
		set_meta("grip_styles",{"R":"pistol","L":"pistol"})
	# 1.4.5: a straight stock's wrist is closed round by the whole hand, the
	# thumb over the top (not raised along the side as on a pistol grip).
	if straight_wrist() and shapes.has("R"):shapes.R=Dictionary(shapes.R).duplicate();shapes.R.thumb_over=true
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
		var mount=Node3D.new();mount.name="GaugeMount";mount.position=right_grip.position*base.scale+Vector3(0,.178,.02);add_child(mount) # 1.4.5: top of the receiver behind the rail
		var gauge=LaserGauge.new();gauge.name="HeatGauge";mount.add_child(gauge)
	name="Gun_"+str(w.get("name","?"))
## 1.4.10 (the user: the hand pumped but the pump stayed put): on the pump-action
## shotgun base the fore-end (and the tube inside it) becomes its own part,
## "Pump", which set_pump() slides back along the gun. The baked base has it
## merged into the body: its triangles (base-local box under the barrel,
## measured on shotgun.scn) are moved to a second mesh.
const PUMP_BOX=AABB(Vector3(-.04,-.1,-.985),Vector3(.08,.088,.21))
const PUMP_TRAVEL=.09 # gun-node metres of a full stroke
var pump:Node3D
## 1.4.10 (the user): a slide pistol's slide - it cycles on each shot, locks back
## when the pistol runs dry and runs forward when the new magazine seats.
const SLIDE_BOX=AABB(Vector3(-.025,-.006,-.235),Vector3(.05,.08,.29))
const SLIDE_TRAVEL=.032
var slide:Node3D
func split_pump():
	if str(look.get("base",""))=="Pistol" and str(spec.get("reload_style",""))=="pistol" and not spec.get("dual",false):slide=split_part(SLIDE_BOX,"Slide")
	if str(look.get("base",""))=="Shotgun" and str(spec.get("reload_style",""))=="shell" and bool(spec.get("single_load",false)):pump=split_part(PUMP_BOX,"Pump")
## Moves the base mesh's triangles inside `box` (base-local) to a part of their
## own under a holder node (returned) that can slide along the gun.
func split_part(box:AABB,part_name:String) -> Node3D:
	var holder:Node3D=null
	for m in base.find_children("*","MeshInstance3D",true,false):
		if m.mesh==null or (is_instance_valid(magazine) and (m==magazine or magazine.is_ancestor_of(m))):continue
		var to_base:Transform3D=relative(m,base)
		var body=ArrayMesh.new();var part=ArrayMesh.new();var moved=0
		for s in range(m.mesh.get_surface_count()):
			var arrays=m.mesh.surface_get_arrays(s);var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var idx:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array(range(v.size()))
			var keep=PackedInt32Array();var take=PackedInt32Array()
			for t in range(0,idx.size(),3):
				var inside=box.has_point(to_base*v[idx[t]]) and box.has_point(to_base*v[idx[t+1]]) and box.has_point(to_base*v[idx[t+2]])
				var into=take if inside else keep
				into.append(idx[t]);into.append(idx[t+1]);into.append(idx[t+2])
			moved+=take.size()
			for pair in [[body,keep],[part,take]]:
				if pair[1].is_empty():continue
				var a=arrays.duplicate();a[Mesh.ARRAY_INDEX]=pair[1]
				pair[0].add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
				pair[0].surface_set_material(pair[0].get_surface_count()-1,m.mesh.surface_get_material(s))
		if moved==0:continue
		m.mesh=body
		if holder==null:holder=Node3D.new();holder.name=part_name+"Holder";m.get_parent().add_child(holder)
		# placed through base space (no reparent: the gun may not be in the tree yet)
		var piece=MeshInstance3D.new();piece.name=part_name;piece.mesh=part;holder.add_child(piece);piece.transform=relative(holder,base).affine_inverse()*to_base
	return holder
func set_slide(amount:float):
	if is_instance_valid(slide):slide.position=Vector3(0,0,SLIDE_TRAVEL*clampf(amount,0.,1.)/maxf(.01,base.scale.z))
## Pump stroke 0..1 (1 = pulled fully back toward the shooter).
func set_pump(amount:float):
	if is_instance_valid(pump):pump.position=Vector3(0,0,PUMP_TRAVEL*clampf(amount,0.,1.)/maxf(.01,base.scale.z))
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
const PAIR_CONVERGE=4. # = Actor.HIP_CONVERGE
func set_pair_spacing(width:float):
	if dual_guns.size()<2:return
	dual_rest=[Vector3.ZERO,Vector3(-width,0,.02)]
	if dual_guns[1].rotation.x==0.:dual_guns[1].position=dual_rest[1]+pair_swing_offset(1)
	# 1.4.5: each pistol turned in so its barrel line crosses the aim line at the
	# hip's convergence distance (Actor.HIP_CONVERGE, in the guns' own units)
	pair_toe=atan2(width*.5,PAIR_CONVERGE/maxf(.01,base.scale.x*scale.x))
	for i in range(dual_guns.size()):
		if dual_guns[i].rotation.x==0.:dual_guns[i].rotation.y=pair_toe*(1. if i==0 else -1.)
# 1.4.5 DUET sprint: the pistols swing like running arms, one forward and a
# little up while the other goes back and down (`amount` metres, +/-).
var pair_swing_amount=0.
var pair_toe=0.
func pair_swing_offset(i:int) -> Vector3:
	var s=pair_swing_amount*(1. if i==0 else -1.)
	# 1.4.10 (the user: like carrying something while running): a pistol swinging
	# forward also moves out from the body, up to 6.5 cm at the front of its swing,
	# and comes back in as it swings back (right pistol out to +x, left to -x).
	var outward=.065*clampf(s/.05,0.,1.)*(1. if i==0 else -1.)
	return Vector3(outward,s*.35,-s)
func set_pair_swing(amount:float):
	pair_swing_amount=amount
	if dual_guns.size()<2 or dual_rest.size()<2:return
	for i in range(dual_guns.size()):
		if dual_guns[i].rotation.x==0.:dual_guns[i].position=dual_rest[i]+pair_swing_offset(i)
# Moves a base's grip markers onto the measured handles and returns the grip
# shapes per hand (handle frame, base units): half extents, rounding and the
# trigger point. Code-built bases (launchers, tools) carry their own shapes.
# A weapon's hand set-up: its base's handles with the look's own "hand" values.
static func hand_set(l:Dictionary) -> Dictionary:
	var h:Dictionary=handles(str(l.get("base",""))).duplicate()
	for k in l.get("hand",{}):h[k]=l.hand[k]
	return h
static func place_handles(node:Node3D,l:Dictionary) -> Dictionary:
	var right:Marker3D=node.get_node("RightGrip");var left:Marker3D=node.get_node("LeftGrip")
	var shapes={}
	# 1.4.5: every weapon may carry its own hand set-up (GunLooks "hand":
	# right / tilt / trigger / grip / index ...) over its base's, so tuning one
	# gun's grip never moves another gun built on the same base.
	var h:Dictionary=hand_set(l)
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
		# 1.4.5 per base: how far the index may swing up toward the trigger and
		# how far under the trigger point it aims (HeroIK defaults otherwise)
		if h.has("index"):shapes.R.index_lift=float(h.index[0]);shapes.R.aim_drop=float(h.index[1])
	if h.has("left"):
		left.position=h.left;left.rotation=Vector3(-float(h.get("left_tilt",0.)),0,0)
		shapes.L={"half":h.get("fore",Vector3(.024,.024,.05)),"round":float(h.get("fore_round",.02))}
	if node.has_node("AimPoint") and h.has("sight"):node.get_node("AimPoint").position=h.sight
	return shapes
## Launchers: show `count` loaded rockets; while reloading (`loading` 0..1) the
## support hand brings the next rocket up behind the tube and pushes it, nose
## first, into the open rear end.
const LOAD_SHOW=.12 # the rocket appears in the hand (1.4.5: early, so the hand is never seen moving empty)
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
	point.z=maxf(point.z,rear+.09) # 1.4.5: a hand's width and a half (the fist's fingers reached into the tube rim at .06)
	return point*base.scale
# Blue glass on both ends of a baked scope.
static func glaze(node:Node3D,l:Dictionary):
	var faces:Array=scopes(str(l.get("base","")))
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
## 1.4.2: the magazine follows ReloadMotion's curve (the hand's), so both leave
## the first-person view together and the new one comes back in the hand; the
## round being loaded shows in the hand for shell / break / revolver cycles, and
## the DUET pistols leave the view one after the other.
var load_round:Node3D
var dual_rest:Array=[]
func animate_reload(t:float,recoil:float=0.,_shot_age:float=10.):
	var style=str(spec.get("reload_style",""))
	if style in ["shell","break","revolver"]:show_load_round(t)
	if dual_guns.size()>1:animate_pair(t)
	if not is_instance_valid(magazine):return
	if t<0.:magazine.transform=mag_rest;magazine.visible=true;return
	var drop=ReloadMotion.mag_drop(t)
	# Gun space -> the magazine's parent (the scaled base). 1.4.6: plus where the
	# support hand really is (HeroCharacter: "mag_hand_delta", the arm may fall
	# short of its target) - the magazine stays in the fist.
	var travel=ReloadMotion.mag_travel(self,t)
	if ReloadMotion.carrying(t):travel+=Vector3(get_meta("mag_hand_delta",Vector3.ZERO))*drop
	var offset=travel/maxf(.01,base.scale.x)
	magazine.transform=Transform3D(Basis(Vector3.FORWARD,ReloadMotion.mag_lean(t))*mag_rest.basis,mag_rest.origin+offset)
	# The magazine stays in the support hand through the swap (old one out, new one in).
	magazine.visible=true
# The baked magazines are open at the top (they sat in the well): drawn from
# both sides so a magazine in the hand never shows as a cut shell.
func double_sided_magazine():
	if not is_instance_valid(magazine):return
	for m in magazine.find_children("*","MeshInstance3D",true,false)+([magazine] if magazine is MeshInstance3D else []):
		if m.mesh==null:continue
		for s in range(m.mesh.get_surface_count()):
			var mat=m.get_surface_override_material(s)
			if mat:m.set_surface_override_material(s,HeroStyle.double_sided(mat))
		if m.material_override:m.material_override=HeroStyle.double_sided(m.material_override)
func show_load_round(t:float):
	if not is_instance_valid(load_round):
		load_round=Node3D.new();load_round.name="LoadRound";add_child(load_round)
		var shell=str(spec.get("reload_style",""))!="revolver"
		# 1.4.5: a little larger than scale (the round was lost in the hand).
		var r=.0105 if shell else .0075;var length=.066 if shell else .042
		# Along -Z (the way it goes in): shell hull + brass head, or case + bullet.
		MeshFactory.cylinder(load_round,Vector3(0,0,-length*.1),r,length*.8,Color("c9423a") if shell else Color("d9b04a"),Vector3(PI/2,0,0),-1.,10)
		MeshFactory.cylinder(load_round,Vector3(0,0,length*.38),r*1.08,length*.24,Color("d6ae55") if shell else Color("c79a3c"),Vector3(PI/2,0,0),-1.,10)
		# (the tapered top of the cone must face -Z: a +90deg turn about X put the
		# point backward, so the bullet looked reversed)
		if not shell:MeshFactory.cylinder(load_round,Vector3(0,0,-length*.58),r*.72,length*.2,Color("b87333"),Vector3(-PI/2,0,0),r*.35,10)
		MeshFactory.merge_children(load_round)
		for m in load_round.get_children():
			if m is MeshInstance3D:m.material_override=HeroStyle.toon_material(outlined,.3);m.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if t<0.:load_round.visible=false;return
	var r=ReloadMotion.round_point(self,t)
	load_round.visible=bool(r[1]);load_round.position=r[0]
func animate_pair(t:float):
	if dual_rest.size()!=dual_guns.size():
		dual_rest=dual_guns.map(func(g):return g.position)
	for i in range(dual_guns.size()):
		var phase=0. if t<0. else clampf((t-.5*i)/.5,0.,1.) if (t>=.5*i and t<.5*(i+1)) else 0.
		var away=sin(phase*PI)
		dual_guns[i].position=dual_rest[i]+Vector3(0,-.7,.22)*smoothstep(0.,1.,away)+pair_swing_offset(i)*(1.-away)
		dual_guns[i].rotation=Vector3(.6*away,pair_toe*(1. if i==0 else -1.)*(1.-away),0)
