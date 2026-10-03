class_name DoorModels
extends RefCounted
## 1.4.6 (the user): the access doors (InteractiveDoor, two sliding leaves)
## rebuilt - the old generated door models are gone. One leaf is 1.15 m wide,
## 2.8 m tall and both faces are finished (players see both sides). A door's
## look follows the buildings around it (the nearest facade's style) and its
## map region (MapRegions), so one map shows different doors in different
## districts.
const W=1.15
const H=2.8
const T=.09 # half thickness
const BRASS=Color("c9a24a")
const STEEL=Color("8c959c")
const DARK=Color("2e343a")
# Facade style -> door families that fit it.
const FAMILIES={
	"harbour":["bulkhead","container","warehouse"],"shipyard":["bulkhead","warehouse","steel"],"logistics":["warehouse","container","steel"],
	"oldtown":["wood_panel","glass_store","frosted","ornate"],"hillside":["wood_panel","plank","frosted"],"canal":["wood_panel","ornate","glass_store"],
	"plaza":["ornate","glass_store","wood_panel"],"market":["glass_store","plank","roller"],"station":["glass_store","frosted","steel"],
	"desert":["steel","plank","warehouse"],"coastal_base":["steel","bulkhead","container"],"orchard":["barn","plank"],"quarry":["plank","steel","roller"],
	"fortress":["plank","ornate","barn"],"mountain_fort":["plank","barn","ornate"],"monastery":["ornate","plank"],"aqueduct":["ornate","wood_panel","plank"],
	"nuclear":["lab","steel","fire_exit"],"power":["steel","fire_exit","lab"],"lab":["lab","glass_store","fire_exit"],"testlab":["lab","fire_exit","steel"],
	"server":["lab","steel","fire_exit"],"wreckyard":["warehouse","steel","container"],"derelict":["warehouse","fire_exit","plank"],
	"furnace":["warehouse","steel","fire_exit"],"steelmill":["warehouse","steel","roller"],"garage":["roller","fire_exit","steel"],
	"greenhouse":["glass_store","lab","wood_panel"],"library":["ornate","shoji","wood_panel"],"highrise":["glass_store","frosted","wood_panel"],
	"vault":["vault","steel"],"range":["plank","steel","roller"]}
static func families() -> Array:
	var out=[]
	for k in FAMILIES:
		for f in FAMILIES[k]:if not f in out:out.append(f)
	return out
## The door family for an access door at `pos` on map `index`.
static func family_at(index:int,pos:Vector3,bounds:Vector2,fronts:Array) -> String:
	var style=DistrictFacade.style_name(index);var best=INF
	for f in fronts:
		if f.size()<=10:continue
		var mid=Vector2((f[0]+f[2])*.5,(f[1]+f[3])*.5);var d=mid.distance_to(Vector2(pos.x,pos.z))
		if d<best:best=d;style=str(f[10])
	var list:Array=FAMILIES.get(style,["wood_panel","steel"])
	return list[(MapRegions.region(index,pos,bounds)+index)%list.size()]
## One leaf (local: x -W/2..W/2, y 0..H, both faces).
static func leaf(k:DistrictFacade.Kit,family:String,hs:int):
	# the core slab both faces share
	var palette={"wood_panel":[Color("7a4a2e"),Color("5a3420"),Color("8f5c3a"),Color("3f5f55")],"ornate":[Color("4a2a1c"),Color("5a3420")],
		"plank":[Color("8a6440"),Color("6f5034")],"barn":[Color("a23a2e"),Color("7a5a3a")],"glass_store":[Color("b8c0c6"),Color("3a3f44")],
		"frosted":[Color("6b4a32"),Color("e8e2d4")],"steel":[Color("5f6b74"),Color("4a5866"),Color("6f7a64")],"bulkhead":[Color("6f8a96"),Color("d8d4c4")],
		"warehouse":[Color("c98a2e"),Color("5a7a9a"),Color("8a8f94")],"container":[Color("b5483a"),Color("2f6f9f"),Color("3f7f5f")],
		"lab":[Color("eef2f3")],"vault":[Color("8a949c")],"fire_exit":[Color("b83a32"),Color("3f7a52")],"shoji":[Color("b98a5a")],"roller":[Color("9aa4aa"),Color("c9a24a")]}
	var cols:Array=palette.get(family,[Color("7a4a2e")]);var col:Color=cols[absi(hs)%cols.size()]
	# (1.5.4: the panels, bands and plates on a leaf stand 2.5 cm apart - DistrictFacade.place_layer -
	# a few millimetres flickered from across the street)
	DistrictFacade.layer_planes.clear();k.separate=true
	k.box(Vector3(0,H*.5,0),Vector3(W,H,T*1.2),col,true)
	for face in [1.,-1.]:
		k.xf=Transform3D(Basis(Vector3.UP,0. if face>0. else PI),Vector3.ZERO)
		face_detail(k,family,col,hs)
	k.xf=Transform3D();k.separate=false;DistrictFacade.layer_planes.clear()
# Front-face detail (z>0) - mirrored onto the back by `leaf`.
static func face_detail(k:DistrictFacade.Kit,family:String,col:Color,hs:int):
	var z=T*.6
	match family:
		"wood_panel":
			for row in range(3):
				for side in [-1.,1.]:
					var ph=[.95,.7,.55][row];var py=[.3,1.4,2.2][row]
					PropModels.cbox(k,Vector3(side*.25,py+ph*.5,z+.012),Vector3(.38,ph,.025),col.lightened(.08),.01)
			k.box(Vector3(0,H-.08,z+.01),Vector3(W,.12,.02),col.darkened(.12),true)
			lever(k,Vector3(-W*.5+.12,1.05,z),BRASS)
		"ornate":
			PropModels.cbox(k,Vector3(0,.6,z+.012),Vector3(.8,.8,.025),col.lightened(.1),.01)
			k.box(Vector3(0,1.75,z+.012),Vector3(.8,1.1,.025),col.lightened(.1),true)
			# arched head panel
			for i in range(8):
				var a0=PI*i/8.;var a1=PI*(i+1)/8.
				var c=Vector3(0,2.3,z+.026)
				PropModels.tri(k,c,c+Vector3(cos(a0)*.4,sin(a0)*.4,0),c+Vector3(cos(a1)*.4,sin(a1)*.4,0),Vector3.BACK,Vector3.BACK,Vector3.BACK,col.lightened(.16))
			PropModels.cbox(k,Vector3(0,1.75,z+.03),Vector3(.18,.18,.02),col.darkened(.15),.01) # carved boss
			PropModels.lathe(k,Vector3(0,1.4,z+.02),Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[.07,0.],[.095,0.],[.095,.02],[.07,.02]],BRASS,12,true) # knocker ring
			lever(k,Vector3(-W*.5+.12,1.05,z),BRASS)
		"plank","barn":
			for i in range(5):
				var x=-W*.5+W*(i+.5)/5.
				k.box(Vector3(x,H*.5,z+.006),Vector3(W/5.-.012,H-.02,.012),col.darkened(.05*(i%2)),true)
			if family=="plank":
				for y in [.45,H-.5]:
					k.box(Vector3(0,y,z+.02),Vector3(W-.04,.1,.016),Color("33373a"),true)
					for i in range(5):k.box(Vector3(-W*.4+i*W*.2,y,z+.03),Vector3(.035,.035,.012),Color("55595c"),true)
				PropModels.lathe(k,Vector3(-W*.5+.18,1.1,z+.02),Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[.06,0.],[.08,0.],[.08,.018],[.06,.018]],Color("33373a"),10,true)
			else:
				var frame=Color("f2ead8")
				for y in [.12,H*.5,H-.12]:k.box(Vector3(0,y,z+.02),Vector3(W,.12,.02),frame,true)
				for side in [-1.,1.]:k.box(Vector3(side*(W*.5-.06),H*.5,z+.02),Vector3(.12,H,.02),frame,true)
				for half in [0,1]:
					k.xf=k.xf*Transform3D(Basis(Vector3.BACK,atan2(H*.5-.24,W-.24)*(1. if half==0 else -1.)),Vector3(0,H*(.25+.5*half),z+.025))
					k.box(Vector3.ZERO,Vector3(sqrt(pow(W-.24,2)+pow(H*.5-.24,2)),.1,.018),frame,true)
					k.xf=k.xf*Transform3D(Basis(Vector3.BACK,atan2(H*.5-.24,W-.24)*(1. if half==0 else -1.)),Vector3(0,H*(.25+.5*half),z+.025)).affine_inverse()
		"glass_store","frosted","lab":
			var frame=col if family!="frosted" else col
			var glass=Color("8fb8cc") if family=="glass_store" else Color("dfe6e8") if family=="frosted" else Color("a8c8d4")
			var top=H-.15;var bottom=.35 if family=="glass_store" else 1.25 if family=="frosted" else 1.5
			if family=="lab":
				# vision slot, colour stripe, push plate
				PropModels.quad(k,Vector3(-.12,bottom,z+.004),Vector3(.12,bottom,z+.004),Vector3(.12,2.35,z+.004),Vector3(-.12,2.35,z+.004),Vector3.BACK,glass)
				k.box(Vector3(0,1.05,z+.008),Vector3(W,.12,.012),[Color("2f8fc0"),Color("e07a2f"),Color("3faa6a")][absi(hs)%3],true)
				k.box(Vector3(-W*.5+.2,1.25,z+.012),Vector3(.12,.3,.01),STEEL,true)
				return
			PropModels.quad(k,Vector3(-W*.5+.09,bottom,z+.004),Vector3(W*.5-.09,bottom,z+.004),Vector3(W*.5-.09,top,z+.004),Vector3(-W*.5+.09,top,z+.004),Vector3.BACK,glass)
			for side in [-1.,1.]:k.box(Vector3(side*(W*.5-.045),H*.5,z+.012),Vector3(.09,H,.02),frame,true)
			k.box(Vector3(0,top+.075,z+.012),Vector3(W,.15,.02),frame,true)
			k.box(Vector3(0,bottom-.06,z+.012),Vector3(W,.12,.02),frame,true)
			if family=="glass_store":
				k.box(Vector3(0,.17,z+.012),Vector3(W,.34,.02),frame.darkened(.15),true)
				PropModels.cyl(k,Vector3(-W*.5+.15,.95,z+.06),Vector3(-W*.5+.15,1.65,z+.06),.018,STEEL,8) # pull handle
				for y in [.98,1.62]:k.box(Vector3(-W*.5+.15,y,z+.035),Vector3(.03,.03,.05),STEEL,true)
				k.box(Vector3(0,1.9,z+.007),Vector3(.5,.06,.004),Color("f4f1e8"),true) # opening hours strip
			else:
				for i in range(4):k.box(Vector3(0,bottom+.3+i*.32,z+.008),Vector3(W-.2,.025,.006),Color("c9d2d4"),true) # frosted bands
				PropModels.cbox(k,Vector3(0,.62,z+.012),Vector3(W-.24,.85,.02),col.lightened(.08),.01)
				lever(k,Vector3(-W*.5+.12,1.05,z),BRASS)
		"steel","fire_exit":
			for i in range(4):k.box(Vector3(-W*.36+i*W*.24,H*.5,z+.008),Vector3(.05,H-.3,.012),col.lightened(.08),true) # stiffeners
			k.box(Vector3(0,.2,z+.012),Vector3(W-.06,.3,.016),STEEL,true) # kick plate
			if family=="steel":
				PropModels.quad(k,Vector3(-.13,1.75,z+.02),Vector3(.13,1.75,z+.02),Vector3(.13,2.2,z+.02),Vector3(-.13,2.2,z+.02),Vector3.BACK,Color("7d97a6"))
				for i in range(3):k.box(Vector3(-.13+i*.13,1.975,z+.024),Vector3(.008,.45,.004),Color("3a3f44"),true) # wire mesh
				for y in [.5,1.4,2.4]:
					for x in [-W*.5+.06,W*.5-.06]:k.box(Vector3(x,y,z+.02),Vector3(.035,.035,.015),Color("3a4248"),true)
				lever(k,Vector3(-W*.5+.12,1.05,z),STEEL)
			else:
				k.box(Vector3(0,1.0,z+.05),Vector3(W-.2,.06,.07),Color("d8dcdf"),true) # push bar
				for x in [-W*.5+.13,W*.5-.13]:k.box(Vector3(x,1.0,z+.025),Vector3(.07,.12,.05),Color("9aa0a4"),true)
				k.box(Vector3(0,2.3,z+.01),Vector3(.5,.22,.012),Color("2fa060"),true) # exit sign
				k.box(Vector3(-.08,2.3,z+.018),Vector3(.18,.05,.006),Color("f4f4f0"),true)
				k.box(Vector3(.06,2.3,z+.018),Vector3(.05,.12,.006),Color("f4f4f0"),true)
		"bulkhead":
			PropModels.cbox(k,Vector3(0,H*.5,z+.012),Vector3(W-.1,H-.3,.03),col.lightened(.06),.08) # raised panel
			var c=Vector3(0,2.05,z+.03)
			k.disc(c,.17,Color("5f7f90"),12)
			PropModels.lathe(k,c-Vector3(0,0,.01),Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[.17,0.],[.24,0.],[.24,.04],[.17,.04]],Color("b8b4a4"),14,true)
			for y in [.6,1.5]:
				for side in [-1.,1.]:
					k.box(Vector3(side*(W*.5-.12),y,z+.05),Vector3(.06,.22,.05),DARK,true) # dogs
			for y in [.35,H-.35]:k.box(Vector3(0,y,z+.035),Vector3(W-.3,.05,.012),col.darkened(.15),true)
		"warehouse","container","roller":
			if family=="roller":
				var n=16
				for i in range(n):k.box(Vector3(0,.1+i*(H-.2)/n,z+.008),Vector3(W,(H-.2)/n*.55,.014),col.lightened(.07),true)
				k.box(Vector3(0,.12,z+.02),Vector3(W,.14,.03),DARK,true)
				k.box(Vector3(0,.5,z+.04),Vector3(.3,.05,.04),STEEL,true)
				return
			var ribs=7
			for i in range(ribs):k.box(Vector3(-W*.5+W*(i+.5)/ribs,H*.5,z+.012),Vector3(W/ribs*.45,H-.1,.02),col.lightened(.07),true)
			if family=="container":
				for x in [-.3,.3]:
					PropModels.cyl(k,Vector3(x,.1,z+.06),Vector3(x,H-.1,z+.06),.022,STEEL,6) # lock rods
					k.box(Vector3(x+.06,1.15,z+.07),Vector3(.12,.05,.03),STEEL,true)
				k.box(Vector3(0,2.35,z+.026),Vector3(.55,.22,.006),Color("f4f1e8"),true) # CSC plate
			else:
				for i in range(6):k.box(Vector3(-W*.5+W*(i+.5)/6.,.22,z+.028),Vector3(W/12.,.26,.008),Color("f0c23f") if i%2==0 else DARK,true) # hazard band
				k.box(Vector3(-W*.5+.16,1.2,z+.04),Vector3(.06,.35,.04),DARK,true)
		"vault":
			var c=Vector3(0,1.4,z)
			PropModels.lathe(k,c,Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[0.,.0],[.48,0.],[.5,.04,col.lightened(.1)],[.44,.07],[.2,.07,col.darkened(.1)],[.18,.09],[0.,.09]],col.lightened(.05),20)
			PropModels.lathe(k,c+Vector3(0,0,.09),Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[.13,0.],[.16,0.],[.16,.03],[.13,.03]],BRASS,14,true) # wheel rim
			for i in range(3):
				var a=TAU*i/3.
				k.xf=k.xf*Transform3D(Basis(Vector3.BACK,a),c+Vector3(0,0,.105))
				k.box(Vector3(.075,0,0),Vector3(.15,.025,.02),BRASS,true)
				k.xf=k.xf*Transform3D(Basis(Vector3.BACK,a),c+Vector3(0,0,.105)).affine_inverse()
			for i in range(12):
				var a=TAU*i/12.
				k.box(c+Vector3(cos(a)*.42,sin(a)*.42,.075),Vector3(.04,.04,.02),Color("5a6268"),true)
			for y in [.25,H-.25]:k.box(Vector3(0,y,z+.02),Vector3(W-.1,.12,.03),col.darkened(.15),true)
		"shoji":
			var frame=col.darkened(.25);var paper=Color("f4ecd8")
			PropModels.quad(k,Vector3(-W*.5+.06,.3,z+.003),Vector3(W*.5-.06,.3,z+.003),Vector3(W*.5-.06,H-.08,z+.003),Vector3(-W*.5+.06,H-.08,z+.003),Vector3.BACK,paper)
			for i in range(4):k.box(Vector3(-W*.5+.06+(W-.12)*i/3.,H*.5+.11,z+.012),Vector3(.03,H-.38,.02),frame,true)
			for j in range(7):k.box(Vector3(0,.3+(H-.38)*j/6.,z+.012),Vector3(W-.1,.03,.02),frame,true)
			k.box(Vector3(0,.15,z+.012),Vector3(W,.3,.02),frame,true)
static func lever(k:DistrictFacade.Kit,at:Vector3,col:Color):
	k.box(at+Vector3(0,0,.02),Vector3(.06,.12,.03),col.darkened(.1),true)
	k.box(at+Vector3(.06,0,.045),Vector3(.14,.025,.025),col,true)
