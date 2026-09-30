class_name CarriedGear
extends RefCounted
## 1.4.2: what a hero carries shows on the body.
##  - The primary not in hand is slung across the back (muzzle up over the left
##    shoulder); the sidearm rides in a right thigh holster.
##  - The utility kit hangs on the belt and vest by its remaining count:
##    grenades (frag, cluster, smoke, flash) front left, spare plates in a
##    lumbar pouch, the medkit back right, folded cover kits back left, the
##    defuse kit on the left hip, the recon marker on the chest.
## Places come from each hero's own body surface (FittedArmor's ray fit, T pose)
## and are bound to the bone under them with the skin's bind pose, so every
## piece sits on the body and moves with it; the armour tier pushes them out.
## Cost: each piece is one merged mesh cached per weapon / kit kind (one draw),
## hidden beyond RANGE, and nodes are rebuilt only when the loadout changes;
## drawing or holstering only toggles visibility.
const RANGE=38.
const ARMOR_BACK=[0.,.026,.058]
const ARMOR_BELT=[0.,0.,.04]
const ARMOR_CHEST=[0.,.026,.056]
const GRENADES=["frag","cluster","smoke","flash"]
const OLIVE=Color("56613f")
const DARK=Color("23262c")
const STRAP=Color("30343b")
const WHITE=Color("e6e8ea")
const RED=Color("d8433a")
const HAZARD=Color("f2c03e")
static var weapon_meshes={}
static var kit_meshes={}
static var layouts={}
## What player `p` carries. `in_hand` is the weapon id drawn (or ""), `item_out`
## whether the gadget is in hand (one fewer on the belt).
static func spec_for(p:Dictionary,in_hand:String,item_out:bool) -> Dictionary:
	var kit=[]
	if GadgetLoadout.has_item(p):
		var role=int(p.role);var gadget=int(p.gadget);var count=int(p.get("gadget_count",0))
		var kind="";var n=count
		if gadget==9:kind="defuse";n=1
		elif GadgetLoadout.cluster(p):kind="cluster"
		elif GadgetLoadout.frag(p):kind="frag"
		elif role==4:kind="flash" if gadget==1 else "smoke";n=int(p.get("flash_count",0)) if gadget==1 else int(p.get("smoke",0))
		elif role==0 and gadget==0:kind="plates"
		elif role==5 and gadget==0:kind="medkit"
		elif role==3 and gadget in [0,1,2]:kind="covers%d" % gadget
		elif role==1 and gadget==0:kind="marker";n=1
		if item_out and kind in GRENADES+["medkit","plates"]:n-=1
		if kind!="" and n>0:kit.append([kind,mini(n,3 if kind in GRENADES or kind=="plates" else 1 if kind in ["medkit","defuse","marker"] else 4)])
	var primary=str(p.get("primary",""));var secondary=str(p.get("secondary",""))
	return {"primary":primary,"secondary":secondary,"primary_out":primary!="" and in_hand==primary,"secondary_out":secondary!="" and in_hand==secondary,"kit":kit,"armor":clampi(int(p.get("armor_max",0))/25,0,2)}
## Shows `spec` (spec_for) on a built hero. Cheap when nothing changed.
static func apply(hero:HeroCharacter,spec:Dictionary):
	if not is_instance_valid(hero) or hero.first_person:return
	hero.set_meta("carried_spec",spec)
	var signature=str([spec.get("primary",""),spec.get("secondary",""),spec.get("kit",[]),spec.get("armor",0)])
	if hero.get_meta("carried","")!=signature:
		hero.set_meta("carried",signature)
		for name in ["StowBack","StowThigh","StowBelt","StowChest"]:
			var old=hero.skeleton.get_node_or_null(name)
			if old:hero.skeleton.remove_child(old);old.queue_free()
		build(hero,spec)
	var back=hero.skeleton.get_node_or_null("StowBack/Primary")
	if back:back.visible=not spec.get("primary_out",false)
	var pistol=hero.skeleton.get_node_or_null("StowThigh/Sidearm")
	if pistol:pistol.visible=not spec.get("secondary_out",false)
static func build(hero:HeroCharacter,spec:Dictionary):
	Catalog.load_all()
	var lay=layout(hero)
	if lay.is_empty():return
	var armor=clampi(int(spec.get("armor",0)),0,2);var m:float=lay.m
	# Primary across the back.
	var primary=str(spec.get("primary",""))
	if primary!="" and Catalog.weapons.has(primary):
		var gun=weapon_mesh(Catalog.get_weapon(primary),false)
		if gun:
			# Muzzle up toward the left shoulder (+X), side flat on the back, sights
			# facing up and right.
			var dir=Vector3(.55,.84,0.).normalized()
			var z=-dir;var x=Vector3(0,0,1)
			var basis=Basis(x,z.cross(x),z)
			var box:AABB=gun.aabb
			var centre:Vector3=lay.back+Vector3(0,0,-1)*(box.size.x*.5+.012+ARMOR_BACK[armor])*m
			piece(hero,"StowBack","Chest",lay,"Primary",gun.mesh,centre,basis,box.get_center())
	# Sidearm in the thigh holster (the holster stays when the pistol is drawn).
	var secondary=str(spec.get("secondary",""))
	if secondary!="" and Catalog.weapons.has(secondary) and GunLooks.hold_kind(Catalog.get_weapon(secondary))=="pistol":
		var w:Dictionary=Catalog.get_weapon(secondary).duplicate();w.dual=false
		var gun=weapon_mesh(w,true)
		if gun:
			var frame:Basis=lay.thigh_basis
			piece(hero,"StowThigh","UpperLeg.R",lay,"Holster",kit_mesh("holster"),lay.thigh,frame,Vector3.ZERO)
			# Muzzle down, slide forward, grip up and back; the bore on the holster line.
			var in_holster=Basis(Vector3(0,0,1),Vector3(1,0,0),Vector3(0,1,0))
			var box:AABB=gun.aabb
			var local=Vector3(-gun.bore,.12-box.end.z,.028-box.get_center().x)
			piece(hero,"StowThigh","UpperLeg.R",lay,"Sidearm",gun.mesh,lay.thigh+frame*(local*m),frame*in_holster,Vector3.ZERO)
	# Kit on the belt / chest.
	for item in spec.get("kit",[]):
		var kind:String=item[0];var n:int=item[1]
		if kind in GRENADES:
			for i in range(n):belt(hero,lay,kind,deg_to_rad(36.+i*19.),armor,"Kit%d" % i)
		elif kind=="plates":belt(hero,lay,"plates%d" % n,PI,armor,"Plates")
		elif kind=="medkit":belt(hero,lay,"medkit",deg_to_rad(-142.),armor,"Medkit")
		elif kind=="defuse":belt(hero,lay,"defuse",deg_to_rad(98.),armor,"Defuse")
		elif kind.begins_with("covers"):belt(hero,lay,kind,deg_to_rad(146.),armor,"Covers")
		elif kind=="marker":
			var dir=Vector3(sin(deg_to_rad(24.)),0,cos(deg_to_rad(24.)))
			var at:Vector3=lay.chest_marker+dir*(ARMOR_CHEST[armor]+.002)*m
			piece(hero,"StowChest","Chest",lay,"Marker",kit_mesh("marker"),at,facing(dir),Vector3.ZERO)
static func belt(hero:HeroCharacter,lay:Dictionary,kind:String,theta:float,armor:int,name:String):
	var dir=Vector3(sin(theta),0,cos(theta))
	var at:Vector3=FittedArmor.point_on(lay.ring,theta)+dir*(ARMOR_BELT[armor]+.002)*lay.m
	piece(hero,"StowBelt","Hips",lay,name,kit_mesh(kind),at,facing(dir),Vector3.ZERO)
# Item frame: +Z out of the body, +Y up.
static func facing(out:Vector3) -> Basis:
	var z=out.normalized();var x=Vector3.UP.cross(z).normalized()
	return Basis(x,z.cross(x),z)
# One stowed mesh under a bone attachment. `at`/`basis` place the piece (its
# `pivot` point, metres) in the body's mesh space.
static func piece(hero:HeroCharacter,group:String,bone:String,lay:Dictionary,name:String,mesh:Mesh,at:Vector3,basis:Basis,pivot:Vector3):
	if mesh==null or not lay.binds.has(bone):return
	var mount:BoneAttachment3D=hero.skeleton.get_node_or_null(group)
	if mount==null:
		mount=BoneAttachment3D.new();mount.name=group;mount.bone_name=bone;hero.skeleton.add_child(mount)
	var node=MeshInstance3D.new();node.name=name;node.mesh=mesh
	var scaled=basis*Basis.from_scale(Vector3.ONE*float(lay.m))
	# The skin's bind pose maps mesh space to the bone: the piece deforms like the body.
	node.transform=Transform3D(lay.binds[bone])*Transform3D(scaled,at-scaled*pivot)
	node.material_override=HeroStyle.toon_material(false,.2)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end=RANGE;node.visibility_range_end_margin=2.
	mount.add_child(node)
const POINTS_PATH="res://assets/heroes/armor/carry_points.json"
const KITS_PATH="res://assets/heroes/armor/kits.res"
const KIT_KINDS=["frag","cluster","smoke","flash","medkit","defuse","holster","marker","plates1","plates2","plates3","covers0","covers1","covers2"]
static var baked_points={}
## Anchor points of a hero (mesh space, T pose) with its skin bind poses. The
## points are baked (tools/bake_armor.gd); measured here only without a bake.
static func layout(hero:HeroCharacter) -> Dictionary:
	if layouts.has(hero.role):return layouts[hero.role]
	var body=FittedArmor.body_of(hero)
	if body==null:return {}
	if baked_points.is_empty() and FileAccess.file_exists(POINTS_PATH):
		baked_points=JSON.parse_string(FileAccess.get_file_as_string(POINTS_PATH))
		if not baked_points is Dictionary:baked_points={"":null}
	var outfit=HeroCharacter.OUTFITS[hero.role]
	var lay:Dictionary=from_json(baked_points[outfit]) if baked_points.has(outfit) else measure(hero)
	if lay.is_empty():layouts[hero.role]={};return {}
	var binds={}
	for i in range(body.skin.get_bind_count()):
		var n=body.skin.get_bind_name(i)
		if n=="":n=hero.skeleton.get_bone_name(body.skin.get_bind_bone(i))
		binds[n]=body.skin.get_bind_pose(i)
	lay.binds=binds
	layouts[hero.role]=lay
	return lay
static func to_json(lay:Dictionary) -> Dictionary:
	var v=func(p:Vector3):return [snappedf(p.x,.0001),snappedf(p.y,.0001),snappedf(p.z,.0001)]
	var b:Basis=lay.thigh_basis
	return {"m":snappedf(lay.m,.00001),"back":v.call(lay.back),"chest_marker":v.call(lay.chest_marker),"thigh":v.call(lay.thigh),"thigh_basis":[v.call(b.x),v.call(b.y),v.call(b.z)],"ring":lay.ring.map(func(p):return v.call(p))}
static func from_json(d) -> Dictionary:
	if not d is Dictionary:return {}
	var v=func(a:Array) -> Vector3:return Vector3(a[0],a[1],a[2])
	return {"m":float(d.m),"back":v.call(d.back),"chest_marker":v.call(d.chest_marker),"thigh":v.call(d.thigh),"thigh_basis":Basis(v.call(d.thigh_basis[0]),v.call(d.thigh_basis[1]),v.call(d.thigh_basis[2])),"ring":d.ring.map(func(a):return v.call(a))}
## Measures the anchor points on the hero's body (FittedArmor's ray fit).
static func measure(hero:HeroCharacter) -> Dictionary:
	var body=FittedArmor.body_of(hero)
	if body==null:return {}
	var r=FittedArmor.rig(hero,body);var at:Dictionary=r.at;var m:float=r.m
	for need in ["Hips","Chest","Neck","UpperLeg.R","LowerLeg.R"]:
		if not at.has(need):return {}
	var hips:Vector3=at.Hips;var chest:Vector3=at.Chest;var neck:Vector3=at.Neck
	var torso=FittedArmor.TORSO+["Shoulder.L","Shoulder.R"]
	var belt_y=hips.y+.045*m
	var back_y=lerpf(hips.y,neck.y,.58)
	var lay={"m":m}
	lay.back=FittedArmor.surface(hero,body,Vector3(chest.x,back_y,lerpf(hips.z,chest.z,.7)),Vector3(0,0,-1),torso)
	lay.ring=FittedArmor.ring(hero,body,Vector3(chest.x,belt_y,hips.z),torso+["UpperLeg.L","UpperLeg.R"],24)
	var marker_y=lerpf(chest.y,neck.y,.05);var dir=Vector3(sin(deg_to_rad(24.)),0,cos(deg_to_rad(24.)))
	lay.chest_marker=FittedArmor.surface(hero,body,Vector3(chest.x,marker_y,chest.z),dir,torso)
	# Holster: outside of the right thigh (-X), a third of the way to the knee.
	var hip:Vector3=at["UpperLeg.R"];var knee:Vector3=at["LowerLeg.R"]
	var up=(hip-knee).normalized();var centre=hip.lerp(knee,.34)
	var out=Vector3(-1,0,-.18);out=(out-up*out.dot(up)).normalized()
	var skin_point=FittedArmor.surface(hero,body,centre,out,["UpperLeg.R"])
	lay.thigh=skin_point+out*.006*m
	lay.thigh_basis=Basis(up.cross(out).normalized(),up,out)
	return lay
## A weapon as one merged mesh (colours baked into vertex colours):
## {"mesh", "aabb" (metres, gun space), "bore" (muzzle height)}.
static func weapon_mesh(w:Dictionary,single:bool) -> Dictionary:
	var key=str([w.get("name",""),single])
	if weapon_meshes.has(key):return weapon_meshes[key]
	var gun=GunModel.new();gun.build(w,false)
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count=0
	for mesh in gun.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh==null or not shown(mesh,gun):continue
		var xf=GunModel.relative(mesh,gun)
		for s in range(mesh.mesh.get_surface_count()):
			var mat:Material=mesh.get_surface_override_material(s)
			if mat==null:mat=mesh.material_override
			if mat==null:mat=mesh.mesh.surface_get_material(s)
			var tint=Color.WHITE;var use_colors=true
			if mat is ShaderMaterial:
				var t=mat.get_shader_parameter("tint");if t is Color:tint=t
				var vc=mat.get_shader_parameter("vertex_color");use_colors=vc==null or float(vc)>.5
			elif mat is BaseMaterial3D:
				if mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:continue
				tint=mat.albedo_color;use_colors=mat.vertex_color_use_as_albedo
			# Colour baked per surface (tint x vertex colour, linear), then appended
			# natively with the part's transform.
			var arrays=mesh.mesh.surface_get_arrays(s)
			var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			if v.is_empty():continue
			var linear_tint=tint.srgb_to_linear();var colors=arrays[Mesh.ARRAY_COLOR]
			if use_colors and colors!=null and colors.size()==v.size():
				if not linear_tint.is_equal_approx(Color.WHITE):
					for i in range(colors.size()):colors[i]=Color(colors[i].r*linear_tint.r,colors[i].g*linear_tint.g,colors[i].b*linear_tint.b)
			else:
				colors=PackedColorArray();colors.resize(v.size());colors.fill(linear_tint)
			var clean=[];clean.resize(Mesh.ARRAY_MAX)
			clean[Mesh.ARRAY_VERTEX]=v;clean[Mesh.ARRAY_NORMAL]=arrays[Mesh.ARRAY_NORMAL];clean[Mesh.ARRAY_COLOR]=colors;clean[Mesh.ARRAY_INDEX]=arrays[Mesh.ARRAY_INDEX]
			var part=ArrayMesh.new();part.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,clean)
			st.append_from(part,0,xf);count+=1
	var bore=gun.muzzle.position.y*gun.base.scale.y if is_instance_valid(gun.muzzle) else 0.
	gun.free()
	if count==0:weapon_meshes[key]={};return {}
	var merged=st.commit()
	weapon_meshes[key]={"mesh":merged,"aabb":merged.get_aabb(),"bore":bore}
	return weapon_meshes[key]
static func shown(node:Node,root:Node) -> bool:
	var n=node
	while n!=null and n!=root:
		if n is Node3D and not n.visible:return false
		n=n.get_parent()
	return true
## A kit piece, from the baked kit surfaces (tools/bake_armor.gd) when present.
static var baked_kits:ArrayMesh
static func kit_mesh(kind:String) -> Mesh:
	if kit_meshes.has(kind):return kit_meshes[kind]
	if baked_kits==null and ResourceLoader.exists(KITS_PATH):baked_kits=load(KITS_PATH)
	var mesh:Mesh=null
	if baked_kits:
		for s in range(baked_kits.get_surface_count()):
			if baked_kits.surface_get_name(s)==kind:
				mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,baked_kits.surface_get_arrays(s))
	if mesh==null:mesh=make_kit(kind)
	kit_meshes[kind]=mesh
	return mesh
## Kit pieces (metres; back face on the body at z=0, +Z outward, +Y up).
static func make_kit(kind:String) -> Mesh:
	var root=Node3D.new()
	var B=func(pos:Vector3,size:Vector3,color:Color,rot:=Vector3.ZERO,bevel:=.35):MeshFactory.box(root,pos,size,color,rot,bevel)
	var C=func(pos:Vector3,radius:float,height:float,color:Color,rot:=Vector3.ZERO):MeshFactory.cylinder(root,pos,radius,height,color,rot,-1.,12)
	match kind:
		"frag":
			B.call(Vector3(0,.012,.004),Vector3(.028,.05,.008),STRAP) # belt loop
			MeshFactory.sphere(root,Vector3(0,0,.034),Vector3(.056,.064,.056),OLIVE)
			C.call(Vector3(0,.036,.034),.011,.018,DARK)
			B.call(Vector3(.016,.02,.04),Vector3(.008,.05,.012),Color("8d949c"),Vector3(0,0,-.25)) # spoon
			C.call(Vector3(-.013,.047,.034),.009,.003,Color("c9ced4"),Vector3(0,0,PI/2)) # pin ring
		"cluster":
			B.call(Vector3(0,.014,.004),Vector3(.03,.06,.008),STRAP)
			C.call(Vector3(0,0,.034),.029,.075,Color("3e4634"))
			for y in [-.024,0.,.024]:C.call(Vector3(0,y,.034),.031,.008,Color("2a2f25"))
			C.call(Vector3(0,.046,.034),.012,.018,DARK)
			B.call(Vector3(.02,.022,.044),Vector3(.008,.05,.012),Color("8d949c"),Vector3(0,0,-.2))
		"smoke":
			B.call(Vector3(0,.012,.004),Vector3(.026,.05,.008),STRAP)
			C.call(Vector3(0,0,.03),.023,.095,Color("7c848c"))
			C.call(Vector3(0,.03,.03),.024,.018,WHITE)
			C.call(Vector3(0,.056,.03),.012,.016,DARK)
			B.call(Vector3(.017,.03,.038),Vector3(.007,.05,.01),Color("8d949c"),Vector3(0,0,-.2))
		"flash":
			B.call(Vector3(0,.012,.004),Vector3(.026,.05,.008),STRAP)
			C.call(Vector3(0,0,.03),.022,.09,Color("2b2f36"))
			for y in [-.02,.012]:C.call(Vector3(0,y,.03),.0232,.01,Color("b7c2cc"))
			C.call(Vector3(0,.053,.03),.012,.016,DARK)
			B.call(Vector3(.016,.03,.038),Vector3(.007,.05,.01),Color("8d949c"),Vector3(0,0,-.2))
		"medkit":
			B.call(Vector3(0,0,.03),Vector3(.13,.1,.055),WHITE,Vector3.ZERO,.45)
			B.call(Vector3(0,0,.059),Vector3(.05,.016,.006),RED);B.call(Vector3(0,0,.059),Vector3(.016,.05,.006),RED)
			B.call(Vector3(0,.052,.03),Vector3(.135,.012,.058),Color("b9bfc6")) # lid seam
			B.call(Vector3(0,.0,.003),Vector3(.03,.12,.008),STRAP)
		"defuse":
			B.call(Vector3(0,0,.024),Vector3(.085,.105,.042),Color("2b2e33"),Vector3.ZERO,.45)
			for i in range(3):B.call(Vector3(-.03+i*.03,-.02,.046),Vector3(.02,.03,.004),HAZARD if i%2==0 else DARK,Vector3(0,0,.5))
			C.call(Vector3(-.014,.066,.024),.006,.04,RED);C.call(Vector3(.012,.066,.024),.006,.04,RED) # cutter handles
			B.call(Vector3(0,.04,.046),Vector3(.07,.02,.004),HAZARD)
		"holster":
			B.call(Vector3(0,-.005,.028),Vector3(.07,.18,.05),Color("262a30"),Vector3.ZERO,.45)
			B.call(Vector3(0,.07,.052),Vector3(.075,.035,.01),Color("363b44")) # retention strap
			for y in [-.035,.045]:B.call(Vector3(0,y,.003),Vector3(.13,.02,.008),STRAP) # thigh straps
			B.call(Vector3(0,.14,.01),Vector3(.03,.08,.008),STRAP) # drop strap to the belt
		"marker":
			B.call(Vector3(0,0,.012),Vector3(.045,.055,.022),Color("30353d"))
			MeshFactory.sphere(root,Vector3(0,.01,.025),Vector3(.016,.016,.01),RED)
			C.call(Vector3(.015,.045,.012),.003,.04,DARK)
		_:
			if kind.begins_with("plates"):
				var n=int(kind.substr(6))
				B.call(Vector3(0,0,.022),Vector3(.24,.13,.04),Color("3a4031"),Vector3.ZERO,.45)
				for i in range(n):B.call(Vector3(0,.07,.012+i*.011),Vector3(.21,.03,.008),Color("9aa3ad"))
				B.call(Vector3(0,.02,.043),Vector3(.2,.02,.004),Color("2c3126"))
			elif kind.begins_with("covers"):
				var tier=int(kind.substr(6));var color:Color=GearModels.TIERS[clampi(tier,0,2)]
				B.call(Vector3(0,0,.032),Vector3(.15,.13,.06),color,Vector3.ZERO,.4)
				B.call(Vector3(0,0,.064),Vector3(.12,.1,.006),color.lightened(.15))
				for i in range(3):B.call(Vector3(-.045+i*.045,-.058,.064),Vector3(.022,.016,.005),HAZARD if i%2==0 else DARK,Vector3(0,0,.5))
				B.call(Vector3(0,.075,.032),Vector3(.1,.018,.03),DARK) # carry handle
			else:
				root.free();return null
	MeshFactory.merge_children(root)
	var merged:MeshInstance3D=root.get_node_or_null("Geometry")
	var mesh:Mesh=merged.mesh if merged else null
	root.free()
	return mesh
