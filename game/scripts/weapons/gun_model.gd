class_name GunModel
extends Node3D
## 1.4 weapon model built from a baked Toon Shooter (CC0) base
## (tools/bake_weapons.gd) plus a per-weapon look from GunLooks: scale,
## palette and small cartoon attachments. Markers: RightGrip, LeftGrip, Muzzle.
## Weapons are authored with the butt (or pistol grip) at the origin, muzzle -Z.
static var bases={}
# Hand handles per base (base-local metres, muzzle -Z): the point each palm
# wraps (right: pistol grip / stock wrist, left: handguard or pump), and the
# rear-sight point the camera lines up with when aiming without optics.
# Measured on the baked meshes with tools/probe_guns.gd.
const HANDLES={
	"AK":{"right":Vector3(0,-.10,-.23),"left":Vector3(0,-.03,-.67),"sight":Vector3(0,.12,-.36)},
	"SMG":{"right":Vector3(0,-.12,-.30),"left":Vector3(0,-.02,-.46),"sight":Vector3(0,.085,-.30)},
	"Pistol":{"right":Vector3(0,-.07,.01),"sight":Vector3(0,.055,0)},
	"Revolver":{"right":Vector3(0,-.085,.02),"sight":Vector3(0,.07,-.02)},
	"Revolver_Small":{"right":Vector3(0,-.09,.01),"sight":Vector3(0,.07,-.02)},
	"Shotgun":{"right":Vector3(0,-.05,-.30),"left":Vector3(0,-.06,-.85),"sight":Vector3(0,.05,-.60)},
	"ShortCannon":{"right":Vector3(0,-.05,-.28),"left":Vector3(0,-.03,-.62),"sight":Vector3(0,.05,-.45)},
	"Sniper":{"right":Vector3(0,-.11,-.24),"left":Vector3(0,-.05,-.62),"sight":Vector3(0,.15,-.45)},
	"Sniper_2":{"right":Vector3(0,-.12,-.25),"left":Vector3(0,-.03,-.70),"sight":Vector3(0,.15,-.42)},
	"RocketLauncher":{"right":Vector3(0,-.26,-.20),"left":Vector3(0,-.15,-.55),"sight":Vector3(0,.22,-.50)},
	"GrenadeLauncher":{"right":Vector3(0,-.16,-.06),"left":Vector3(0,-.05,-.65),"sight":Vector3(0,.09,-.13)}}
var spec={}
var look={}
var base:Node3D
var muzzle:Marker3D
var right_grip:Marker3D
var left_grip:Marker3D
var aim_point:Marker3D # rear sight / optic centre, lined up with the camera when aiming
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
	base=GunLooks.build_tool(look.tool) if look.has("tool") else base_scene(look.base).instantiate()
	add_child(base)
	base.scale=Vector3.ONE*float(look.get("scale",1.))
	muzzle=base.get_node("Muzzle");right_grip=base.get_node("RightGrip");left_grip=base.get_node("LeftGrip")
	var pistol=GunLooks.hold_kind(w)=="pistol"
	aim_point=Marker3D.new();aim_point.name="AimPoint";base.add_child(aim_point)
	aim_point.position=Vector3(0,muzzle.position.y+(.05 if pistol else .07),right_grip.position.z-(0. if pistol else .10))
	place_handles(base,look)
	magazine=base.get_node_or_null("Magazine")
	if magazine:mag_rest=magazine.transform
	for mesh in base.find_children("*","MeshInstance3D",true,false):paint(mesh)
	GunLooks.attach(self,look)
	# A dot or scope on top replaces the iron rear sight as the aiming point.
	for kind in look.get("attach",[]):
		if kind=="dot":aim_point.position=Vector3(0,muzzle.position.y+.075,right_grip.position.z-.115)
		elif kind=="scope":aim_point.position=Vector3(0,muzzle.position.y+.075,right_grip.position.z-.09)
	muzzles=[muzzle];dual_guns=[base]
	set_meta("grip_styles",{"R":"pistol","L":"support"})
	if w.get("dual",false):
		var second:Node3D=base_scene(look.base).instantiate();add_child(second);second.name="LeftPistol"
		second.scale=base.scale;second.position=Vector3(-.2,0,.02)
		for mesh in second.find_children("*","MeshInstance3D",true,false):paint(mesh)
		place_handles(second,look)
		left_grip=second.get_node("RightGrip");muzzles.append(second.get_node("Muzzle"));dual_guns.append(second)
		set_meta("grip_styles",{"R":"pistol","L":"pistol"})
	for m in muzzles:
		var f=Node3D.new();f.name="MuzzleFlash";m.add_child(f)
	flash=muzzle.get_node("MuzzleFlash")
	if w.get("laser",false):
		# Heat gauge sits on the right side above the grip (LaserGauge lays itself out from there).
		var mount=Node3D.new();mount.name="GaugeMount";mount.position=right_grip.position*base.scale+Vector3(-.03,.02,.06);add_child(mount)
		var gauge=LaserGauge.new();gauge.name="HeatGauge";mount.add_child(gauge)
	name="Gun_"+str(w.get("name","?"))
func grip(side:String) -> Node3D:return right_grip if side=="R" else left_grip
# Moves a base's grip markers onto the measured handles. The support hand's
# marker rolls a little so the hand comes up from the lower left.
static func place_handles(node:Node3D,l:Dictionary):
	var h:Dictionary=HANDLES.get(str(l.get("base","")),{})
	var right:Marker3D=node.get_node("RightGrip");var left:Marker3D=node.get_node("LeftGrip")
	if h.has("right"):right.position=h.right
	if h.has("left"):left.position=h.left;left.rotation=Vector3(0,0,.35)
	if node.has_node("AimPoint") and h.has("sight"):node.get_node("AimPoint").position=h.sight
func paint(mesh:MeshInstance3D):
	if look.has("tool"):
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
	magazine.visible=not (t>.30 and t<.55)
