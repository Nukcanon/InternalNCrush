class_name PropCatalog
extends RefCounted
## 1.4.6 (the user): every code-built map prop remodelled (shape and finish),
## plus new themed pieces, and the props of one map change by region
## (MapRegions): a harbour quarter shows lobster pots and nets, the market
## quarter produce and sacks, the yard drums and generators. Each remodel
## keeps its old footprint (the collision and navigation boxes stand), and a
## themed swap only trades pieces of the same size class.
const P=preload("res://scripts/prop_models.gd")
const WOOD=Color("9a6a42")
const DARK_WOOD=Color("5f4129")
const IRON=Color("3a3f45")
const STEEL=Color("8a939a")
const CONCRETE=Color("b4b0a6")
const LEAF=[Color("5f9a4a"),Color("4f8a3f"),Color("6faa55"),Color("7fb05a")]
const BLOOM=[Color("e05a7a"),Color("f0c24f"),Color("e8784f"),Color("b56ad0"),Color("f4f1e8")]
const KINDS=["crate_stack","planter","planter_long","cabinet","rock_pile","bookcase","lab_bench","transformer","server_block","bollards",
	"bench","market_stall","fruit_crates","fish_crates","desk","woodplanks_stack","pots","weapon_rack","ingots","potting_bench","money_cart",
	"deposit_block","cafe_table","reading_table","fountain","workbench","luggage","tool_chest","hay_bale","globe","pallet_load","laundry",
	"bike_rack","well","target_stand",
	# new themed pieces
	"ammo_crates","equipment_cases","sack_stack","lobster_pots","produce_boxes","sack_pallet","drum_pallet","brick_pallet","water_barrels",
	"generator","milk_churns","vending_machine","phone_booth","wheelie_bins","notice_board","mailbox","fire_hydrant","statue","net_rack",
	"compressor","wheelbarrow","flower_cart",
	# water safety (the user): in front of deadly water
	"warning_sign","lifebuoy_stand"]
static func has(kind:String) -> bool:return kind in KINDS
# --- regional themes ------------------------------------------------------
# Size classes: a swap only trades pieces of the same class.
const CLASSES={"big":["crate_stack","ammo_crates","equipment_cases","sack_stack","lobster_pots","produce_boxes"],
	"mid":["pallet_load","sack_pallet","drum_pallet","brick_pallet","water_barrels","generator"],
	"low":["cask_pair","drums","milk_churns"],
	"decor":["pots","bike_rack","luggage","vending_machine","phone_booth","wheelie_bins","notice_board","mailbox","fire_hydrant","net_rack","compressor","wheelbarrow","flower_cart"]}
const THEMES={
	"town_cafe":{"big":["produce_boxes","crate_stack"],"mid":["sack_pallet","pallet_load"],"low":["cask_pair","milk_churns"],"decor":["vending_machine","mailbox","phone_booth","notice_board","pots"]},
	"town_market":{"big":["produce_boxes","sack_stack"],"mid":["sack_pallet","water_barrels"],"low":["cask_pair","drums"],"decor":["flower_cart","wheelie_bins","pots","bike_rack"]},
	"harbour_fish":{"big":["lobster_pots","crate_stack"],"mid":["drum_pallet","pallet_load"],"low":["drums","cask_pair"],"decor":["net_rack","fire_hydrant","wheelie_bins"]},
	"industrial":{"big":["equipment_cases","crate_stack"],"mid":["drum_pallet","generator","brick_pallet"],"low":["drums"],"decor":["wheelie_bins","notice_board","fire_hydrant","compressor"]},
	"military":{"big":["ammo_crates","equipment_cases"],"mid":["water_barrels","sack_pallet","generator"],"low":["drums"],"decor":["notice_board","fire_hydrant","compressor"]},
	"farm":{"big":["sack_stack","produce_boxes"],"mid":["sack_pallet","pallet_load"],"low":["milk_churns","cask_pair"],"decor":["wheelbarrow","flower_cart","pots"]},
	"lab":{"big":["equipment_cases","crate_stack"],"mid":["drum_pallet","generator"],"low":["drums"],"decor":["vending_machine","notice_board"]},
	"old":{"big":["sack_stack","crate_stack"],"mid":["sack_pallet","brick_pallet"],"low":["cask_pair","milk_churns"],"decor":["pots","notice_board","wheelbarrow"]}}
const STYLE_THEMES={"harbour":["harbour_fish","industrial","town_market"],"shipyard":["industrial","harbour_fish"],"logistics":["industrial","harbour_fish","town_market"],
	"oldtown":["town_cafe","town_market","old"],"hillside":["old","farm","town_cafe"],"canal":["town_cafe","harbour_fish","town_market"],"plaza":["town_cafe","old"],
	"market":["town_market","farm","town_cafe"],"station":["town_cafe","industrial"],"desert":["military","farm"],"coastal_base":["military","harbour_fish"],
	"orchard":["farm","town_market"],"quarry":["industrial","farm"],"fortress":["old","military","farm"],"mountain_fort":["old","military"],
	"monastery":["old","farm"],"aqueduct":["old","town_cafe"],"nuclear":["industrial","lab"],"power":["industrial","lab"],"lab":["lab"],"testlab":["lab","industrial"],
	"server":["lab"],"wreckyard":["industrial","harbour_fish"],"derelict":["industrial","old"],"furnace":["industrial"],"steelmill":["industrial"],
	"garage":["industrial"],"greenhouse":["farm","lab"],"library":["old"],"highrise":["town_cafe","lab"],"vault":["lab","military"],"range":["military","industrial"]}
static func theme_of(index:int,region:int) -> String:
	var list:Array=STYLE_THEMES.get(DistrictFacade.style_name(index),["town_cafe"])
	return list[(region+index)%list.size()]
## The piece a region shows in place of `kind` (same size class) - or `kind`.
static func themed(kind:String,index:int,region:int,hs:int) -> String:
	for cls in CLASSES:
		if kind in CLASSES[cls]:
			var options:Array=THEMES[theme_of(index,region)].get(cls,[])
			if options.is_empty():return kind
			return options[absi(hs)%options.size()]
	return kind
# --- helpers ----------------------------------------------------------------
static func sphere(k:DistrictFacade.Kit,c:Vector3,r:Vector3,col:Color,sides:int=8):
	var prof=[];var rings=4
	for i in range(rings+1):
		var a=-PI*.5+PI*i/rings;prof.append([cos(a)*r.x,sin(a)*r.y])
	prof[0][0]=0.;prof[rings][0]=0.
	var frame=Basis(Vector3.RIGHT,Vector3.UP,Vector3.BACK).scaled(Vector3(1,1,r.z/maxf(.001,r.x)))
	P.lathe(k,c,frame,prof,col,sides)
## Leafy bush: a few overlapping squashed balls.
static func bush(k:DistrictFacade.Kit,c:Vector3,r:float,hs:int):
	for i in range(3):
		var a=TAU*(hs*7+i*3)/9.
		var o=Vector3(cos(a)*r*.35,r*(.15+.1*(i%2)),sin(a)*r*.35)
		sphere(k,c+o,Vector3(r*.7,r*.6,r*.7),LEAF[(hs+i)%LEAF.size()],7)
## Faceted rock (seeded jitter on a squashed ball).
static func rock(k:DistrictFacade.Kit,c:Vector3,size:Vector3,col:Color,seed:int):
	var rings=3;var sides=6;var pts=[]
	for i in range(rings+1):
		var a=-PI*.5+PI*i/rings;var row=[]
		for j in range(sides):
			var b=TAU*j/sides+(i%2)*.4
			var jit=.78+.44*float(((seed*131+i*37+j*71)%97))/97.
			var r=cos(a)*jit
			row.append(c+Vector3(cos(b)*r*size.x*.5,(sin(a)*.5+.5)*size.y*(.85+.15*jit),sin(b)*r*size.z*.5))
		pts.append(row)
	for i in range(rings):
		for j in range(sides):
			var a0=pts[i][j];var a1=pts[i][(j+1)%sides];var b0=pts[i+1][j];var b1=pts[i+1][(j+1)%sides]
			var n=((a1-a0).cross(b0-a0)).normalized()
			if n.dot((a0+b1)*.5-c-Vector3.UP*size.y*.5)<0.:n=-n
			var shade=col.darkened(.06*((i+j)%3))
			P.tri(k,a0,a1,b1,n,n,n,shade);P.tri(k,a0,b1,b0,n,n,n,shade)
## Slatted wooden crate (open-slat sides, corner posts, top boards).
static func crate(k:DistrictFacade.Kit,c:Vector3,s:Vector3,wood:Color,label:bool=false,yaw:float=0.):
	var keep=k.xf;k.xf=keep*Transform3D(Basis(Vector3.UP,yaw),c)
	k.box(Vector3(0,s.y*.5,0),s-Vector3(.04,.02,.04),wood.darkened(.18),true)
	for sx in [-1.,1.]:
		for sz in [-1.,1.]:k.box(Vector3(sx*(s.x*.5-.035),s.y*.5,sz*(s.z*.5-.035)),Vector3(.07,s.y,.07),wood.darkened(.05),true)
	var slats=3
	for i in range(slats):
		var y=s.y*(i+.5)/slats
		k.box(Vector3(0,y,0),Vector3(s.x,s.y/slats*.62,s.z+.012),wood.lightened(.04*(i%2)),true)
	k.box(Vector3(0,s.y-.02,0),Vector3(s.x-.02,.04,s.z-.02),wood.lightened(.08),true)
	if label:k.box(Vector3(0,s.y*.55,s.z*.5+.012),Vector3(s.x*.42,s.y*.22,.006),Color("efe8d2"),true)
	k.xf=keep
static func sack(k:DistrictFacade.Kit,c:Vector3,size:Vector3,col:Color,yaw:float=0.):
	var keep=k.xf;k.xf=keep*Transform3D(Basis(Vector3.UP,yaw),c)
	# a filled sack lying flat: a soft pillow, fuller in the middle, seams at the ends
	var r=minf(size.x,minf(size.y,size.z))
	P.cbox(k,Vector3(0,size.y*.42,0),Vector3(size.x,size.y*.84,size.z),col,r*.38)
	P.cbox(k,Vector3(0,size.y*.62,0),Vector3(size.x*.8,size.y*.7,size.z*.8),col.lightened(.04),r*.3)
	var long_x=size.x>=size.z
	for e in [-1.,1.]:
		var o=Vector3(e*size.x*.47,size.y*.45,0) if long_x else Vector3(0,size.y*.45,e*size.z*.47)
		k.box(o,Vector3(.04,size.y*.5,size.z*.7) if long_x else Vector3(size.x*.7,size.y*.5,.04),col.darkened(.15),true)
	k.xf=keep
static func drum_at(k:DistrictFacade.Kit,at:Vector3,col:Color,label:bool,r:float=.29,h:float=.88):
	P.drum(k,at,r,h,col,label)
static func pallet(k:DistrictFacade.Kit,c:Vector3,s:Vector3):
	for x in [-1.,0.,1.]:k.box(c+Vector3(x*(s.x*.5-.05),.05,0),Vector3(.1,.1,s.z),WOOD.darkened(.12),true)
	for i in range(5):k.box(c+Vector3(0,.12,-s.z*.5+s.z*(i+.5)/5.),Vector3(s.x,.04,s.z/5.-.03),WOOD.lightened(.06),true)
static func panel_grid(k:DistrictFacade.Kit,x0:float,x1:float,y0:float,y1:float,z:float,nx:int,ny:int,col:Color,gap:float=.03):
	for i in range(nx):
		for j in range(ny):
			var w=(x1-x0)/nx;var h=(y1-y0)/ny
			k.box(Vector3(x0+w*(i+.5),y0+h*(j+.5),z),Vector3(w-gap,h-gap,.02),col,true)
# --- builders ---------------------------------------------------------------
static func build(k:DistrictFacade.Kit,kind:String,hs:int) -> AABB:
	match kind:
		"crate_stack":
			var w=[WOOD,Color("b0844f"),Color("8a5a36")][absi(hs)%3]
			crate(k,Vector3(-.45,0,0),Vector3(.88,.88,.88),w,true)
			crate(k,Vector3(.45,0,.1),Vector3(.78,.78,.78),w.lightened(.06),false,.12)
			crate(k,Vector3(-.36,.88,0),Vector3(.76,.76,.76),w.darkened(.04),hs%2==0,-.1)
			return AABB(Vector3(-.9,0,-.45),Vector3(1.75,1.7,1.))
		"planter","planter_long":
			var w=2.4 if kind=="planter_long" else 1.3
			var body=[Color("b5634a"),CONCRETE,Color("7a6a5a"),Color("8a9a8a")][absi(hs)%4]
			P.cbox(k,Vector3(0,.3,0),Vector3(w,.6,.8),body,.06)
			k.box(Vector3(0,.61,0),Vector3(w+.06,.06,.86),body.lightened(.1),true) # rim
			k.box(Vector3(0,.645,0),Vector3(w-.14,.04,.66),Color("5a3f2a"),true) # soil (1.5.4: its top 2.5 cm over the rim's - they shared a plane and flickered)
			var n=int(w/.42)
			for i in range(n):
				var x=-w*.5+.24+i*(w-.48)/maxf(1.,n-1)
				if (hs+i)%3==2:
					for f in range(4):sphere(k,Vector3(x+(f%2-.5)*.14,.72+.04*(f/2),(f/2-.5)*.14),Vector3(.07,.06,.07),BLOOM[(hs+i+f)%BLOOM.size()],6)
					bush(k,Vector3(x,.62,0),.2,hs+i)
				else:bush(k,Vector3(x,.6,(i%2-.5)*.12),.26,hs+i)
			return AABB(Vector3(-w*.5,0,-.4),Vector3(w,.9,.8))
		"bench":
			var stone=absi(hs)%3==2
			if stone:
				for x in [-.7,.7]:P.cbox(k,Vector3(x,.22,0),Vector3(.24,.44,.46),CONCRETE,.04)
				P.cbox(k,Vector3(0,.5,0),Vector3(1.9,.1,.52),CONCRETE.lightened(.08),.04)
				return AABB(Vector3(-.95,0,-.28),Vector3(1.9,.95,.56))
			for x in [-.82,.82]:
				# cast-iron ends: leg, arm, back post
				k.box(Vector3(x,.22,.12),Vector3(.06,.44,.06),IRON,true);k.box(Vector3(x,.22,-.14),Vector3(.06,.44,.06),IRON,true)
				k.box(Vector3(x,.46,0),Vector3(.06,.05,.5),IRON,true)
				k.box(Vector3(x,.62,.2),Vector3(.06,.3,.05),IRON,true) # arm post
				k.box(Vector3(x,.78,.1),Vector3(.06,.04,.28),IRON,true) # arm
				k.box(Vector3(x,.72,-.22),Vector3(.06,.52,.05),IRON,true) # back post
			var slat=[WOOD,Color("6f8a6a"),Color("a0765a")][absi(hs)%3]
			for i in range(4):k.box(Vector3(0,.49,-.17+i*.12),Vector3(1.9,.04,.1),slat.darkened(.05*(i%2)),true)
			for i in range(3):k.box(Vector3(0,.62+i*.11,-.24),Vector3(1.9,.08,.03),slat.lightened(.04*(i%2)),true)
			return AABB(Vector3(-.95,0,-.28),Vector3(1.9,.95,.56))
		"pallet_load":
			pallet(k,Vector3.ZERO,Vector3(1.3,0,1.1))
			var bc=[Color("c9a36d"),Color("b8894f"),Color("d8b47a")][absi(hs)%3]
			for i in range(4):
				var cx=-.32+(i%2)*.64;var cz=-.25+(i/2)*.5
				k.box(Vector3(cx,.43,cz),Vector3(.6,.6,.48),bc.darkened(.05*(i%3)),true)
				k.box(Vector3(cx,.43,cz+.241),Vector3(.6,.06,.002),Color("e3d6b4"),true) # tape
			k.box(Vector3(0,.95,0),Vector3(1.2,.38,1.0),bc.lightened(.05),true)
			# straps
			for x in [-.35,.35]:k.box(Vector3(x,.66,0),Vector3(.04,1.0,1.06),Color("3a5a8a"),true)
			return AABB(Vector3(-.65,0,-.55),Vector3(1.3,1.16,1.1))
		"cabinet":
			var c=[Color("a8b6bc"),Color("7f8f99"),Color("c8b89a"),Color("6f8a6a")][absi(hs)%4]
			for side in [-1.,1.]:
				var x=side*.3
				P.cbox(k,Vector3(x,.9,0),Vector3(.58,1.8,.5),c.darkened(.04*(side+1.)),.02)
				for f in [1.,-1.]:
					var z=f*.255
					for v in range(5):k.box(Vector3(x,1.55+v*.04,z),Vector3(.3,.015,.01),c.darkened(.3),true) # vents
					k.box(Vector3(x+.2,1.0,z+f*.012),Vector3(.03,.18,.03),IRON,true) # handle
					k.box(Vector3(x,1.75,z),Vector3(.14,.06,.008),Color("f4f1e8"),true) # number
			k.box(Vector3(0,1.81,0),Vector3(1.2,.03,.52),c.darkened(.2),true)
			return AABB(Vector3(-.6,0,-.25),Vector3(1.2,1.8,.5))
		"rock_pile":
			var rc=[Color("a8a090"),Color("9c9484"),Color("b4ac9c")]
			var spots=[[Vector3(-.55,0,.05),Vector3(.95,.75,.85)],[Vector3(.45,0,-.15),Vector3(.9,.65,.8)],[Vector3(0,.5,0),Vector3(.75,.65,.7)],[Vector3(-.2,0,.38),Vector3(.7,.45,.45)],[Vector3(.45,.45,.2),Vector3(.55,.45,.5)]]
			for i in range(spots.size()):rock(k,spots[i][0],spots[i][1],rc[(absi(hs)+i)%3],hs*5+i)
			for i in range(4):rock(k,Vector3(-.8+i*.5,0,-.45+.2*(i%2)),Vector3(.22,.16,.2),rc[i%3].darkened(.1),hs+i*3) # pebbles
			return AABB(Vector3(-1.05,0,-.6),Vector3(2.,1.2,1.2))
		"bookcase":
			var frame=Color("6b4630")
			for f in [1.,-1.]:
				k.box(Vector3(0,1.1,f*.17),Vector3(2.,2.2,.02),frame.darkened(.15),true) # back panel
			for x in [-1.,0.,1.]:k.box(Vector3(x*.97,1.1,0),Vector3(.06,2.2,.7),frame,true)
			for r in range(5):k.box(Vector3(0,.06+r*.5,0),Vector3(2.,.04,.7),frame.lightened(.06),true)
			k.box(Vector3(0,2.22,0),Vector3(2.08,.08,.76),frame.darkened(.1),true) # crown
			var book=[Color("a33a3a"),Color("3a5a8a"),Color("3a7a4a"),Color("c9a03a"),Color("6a4a8a"),Color("d8cbb0"),Color("2f2f2f")]
			for f in [1.,-1.]:
				for r in range(4):
					var x=-.93;var i=0
					while x<.9:
						var bw=[.05,.07,.06,.08,.045][(absi(hs)+r*3+i)%5];var bh=[.36,.32,.4,.3,.38][(absi(hs)+i+r)%5]
						if absf(x)<.04:x+=.07;i+=1;continue
						var lean=(absi(hs)+r+i)%11==0
						k.box(Vector3(x+bw*.5,.08+r*.5+bh*.5,f*.08),Vector3(bw-.006,bh,.24),book[(absi(hs)*3+r*5+i)%book.size()],true)
						if lean:x+=.08
						x+=bw;i+=1
			return AABB(Vector3(-1.,0,-.35),Vector3(2.,2.2,.7))
		"lab_bench":
			P.cbox(k,Vector3(0,.44,0),Vector3(2.2,.88,.8),Color("e8ecef"),.02)
			for i in range(4):
				var x=-.82+i*.55
				for f in [1.,-1.]:
					k.box(Vector3(x,.48,f*.405),Vector3(.5,.7,.01),Color("dfe5e8"),true)
					k.box(Vector3(x,.78,f*.415),Vector3(.18,.025,.02),STEEL,true)
			k.box(Vector3(0,.91,0),Vector3(2.3,.05,.9),Color("2f3a44"),true) # epoxy top
			k.box(Vector3(-.65,.935,0),Vector3(.5,.02,.4),Color("4a5866"),true) # sink
			P.cyl(k,Vector3(-.65,.93,-.25),Vector3(-.65,1.2,-.25),.015,STEEL,6);k.box(Vector3(-.65,1.2,-.15),Vector3(.03,.03,.2),STEEL,true)
			k.box(Vector3(.55,1.08,-.25),Vector3(.9,.03,.3),Color("e8ecef"),true) # reagent shelf
			for x in [.12,.98]:k.box(Vector3(x,1.0,-.25),Vector3(.03,.17,.3),STEEL,true)
			for i in range(4):P.lathe(k,Vector3(.2+i*.22,1.095,-.25),Basis(),[[0.,0.],[.04,0.],[.04,.1],[.015,.13],[.015,.16],[0.,.16]],Color("9fd6cf"),8) # bottles
			# microscope
			k.box(Vector3(.35,.95,.18),Vector3(.18,.04,.14),IRON,true)
			k.box(Vector3(.35,1.06,.12),Vector3(.05,.2,.05),IRON,true)
			k.xf=Transform3D(Basis(Vector3.RIGHT,-.5),Vector3(.35,1.16,.17));P.cyl(k,Vector3.ZERO,Vector3(0,.16,0),.025,Color("e8ecef"),8);k.xf=Transform3D()
			for i in range(3):P.lathe(k,Vector3(-.15+i*.12,.935,.2),Basis(),[[0.,0.],[.035,0.],[.035,.09],[.03,.1],[0.,.1]],Color("bfe8f0"),8) # beakers
			return AABB(Vector3(-1.15,0,-.45),Vector3(2.3,1.2,.9))
		"transformer":
			var body=[Color("8a9a92"),Color("6f8a7a"),Color("9aa4a8")][absi(hs)%3]
			k.box(Vector3(0,.06,0),Vector3(1.6,.12,1.1),IRON,true) # skid
			P.cbox(k,Vector3(0,.78,0),Vector3(1.1,1.3,.8),body,.04)
			for f in [1.,-1.]:
				for i in range(7):k.box(Vector3(-.45+i*.15,.8,f*.47),Vector3(.05,1.05,.14),body.darkened(.12),true) # radiator fins
			k.box(Vector3(0,1.46,0),Vector3(1.16,.06,.86),body.darkened(.2),true)
			for i in range(3):
				P.lathe(k,Vector3(-.35+i*.35,1.48,0),Basis(),[[0.,0.],[.07,0.],[.07,.03],[.05,.04],[.08,.06],[.05,.08],[.08,.1],[.05,.12],[.03,.14],[.03,.18],[0.,.18]],Color("c8c0a8"),8) # bushings
			k.box(Vector3(0,1.0,.405),Vector3(.3,.3,.01),Color("f0c23f"),true);k.box(Vector3(0,1.0,.412),Vector3(.12,.16,.005),Color("2a2a2a"),true)
			return AABB(Vector3(-.8,0,-.55),Vector3(1.6,1.6,1.1))
		"server_block":
			var shell=Color("262c33")
			for i in range(4):
				var x=-.9+i*.6
				P.cbox(k,Vector3(x,1.04,0),Vector3(.58,2.08,1.0),shell,.02)
				for f in [1.,-1.]:
					var z=f*.505
					k.box(Vector3(x,1.04,z),Vector3(.5,1.9,.01),Color("323a42"),true)
					for r in range(18):
						k.box(Vector3(x,.18+r*.1,z+f*.006),Vector3(.44,.07,.006),Color("3c454e") if r%3 else Color("2b3137"),true)
						if (absi(hs)+i+r)%2==0:k.box(Vector3(x+.17,.18+r*.1,z+f*.012),Vector3(.025,.025,.006),[Color("3fe07a"),Color("2fb8e0"),Color("f0c23f")][(absi(hs)+i*3+r)%3],true)
			k.box(Vector3(0,2.12,0),Vector3(2.4,.06,.4),Color("4a5560"),true) # cable tray
			return AABB(Vector3(-1.2,0,-.5),Vector3(2.4,2.1,1.))
		"bollards":
			for x in [-.7,.7]:
				P.lathe(k,Vector3(x,0,0),Basis(),[[0.,0.],[.26,0.],[.26,.08],[.19,.12],[.16,.4],[.18,.6],[.25,.66],[.25,.74],[.2,.8],[0.,.82]],Color("2f3438"),12)
			# rope looped round one
			P.lathe(k,Vector3(-.7,.5,0),Basis(),[[.17,0.],[.21,0.],[.21,.05],[.17,.05]],Color("c9b27a"),12,true)
			return AABB(Vector3(-.95,0,-.26),Vector3(1.9,.82,.52))
		"market_stall":
			var cloth=[Color("d24c3f"),Color("2f7fbf"),Color("2f9a6a"),Color("e0a02f")][absi(hs)%4]
			P.cbox(k,Vector3(0,.45,0),Vector3(2.4,.9,.9),WOOD,.03)
			for i in range(6):k.box(Vector3(-1.0+i*.4,.45,.455),Vector3(.36,.8,.01),WOOD.darkened(.06*(i%2)),true)
			k.box(Vector3(0,.92,0),Vector3(2.5,.05,1.0),WOOD.lightened(.12),true)
			for i in range(5):
				var x=-1.+i*.5
				crate(k,Vector3(x,.945,.1),Vector3(.42,.16,.5),WOOD.lightened(.1))
				var fruit=[Color("e05a3a"),Color("f0c24f"),Color("8fbf5a"),Color("d9577a"),Color("f09a3a")][(absi(hs)+i)%5]
				for f in range(6):sphere(k,Vector3(x-.12+(f%3)*.12,1.13,.0+(f/3)*.2),Vector3(.055,.05,.055),fruit,6)
			for x in [-1.2,1.2]:
				for z in [-.45,.45]:P.cyl(k,Vector3(x,0,z),Vector3(x,2.3,z),.035,DARK_WOOD,6)
			for i in range(6):
				var x0=-1.35+i*.45
				P.quad(k,Vector3(x0,2.2,.75),Vector3(x0+.45,2.2,.75),Vector3(x0+.45,2.5,-.6),Vector3(x0,2.5,-.6),Vector3(0,.97,.24).normalized(),cloth if i%2==0 else Color("f4ead7"))
				P.quad(k,Vector3(x0,2.2,.75),Vector3(x0+.45,2.2,.75),Vector3(x0+.45,2.0,.78),Vector3(x0,2.0,.78),Vector3.BACK,cloth.darkened(.1) if i%2==0 else Color("e4dac7")) # valance
			k.box(Vector3(.6,1.25,.44),Vector3(.4,.25,.02),Color("2f3a2f"),true) # price board
			return AABB(Vector3(-1.25,0,-.5),Vector3(2.5,1.2,1.))
		"fruit_crates","fish_crates","produce_boxes":
			var big=kind=="produce_boxes"
			var rows=3 if big else 2
			for i in range(4*rows/2):
				var col=i%2;var lvl=i/2
				var c=Vector3(-.5+col*1.,.0+lvl*.42,((lvl%2)-.5)*.1)
				if big:c=Vector3(-.45+col*.9,lvl*.56,0)
				var s=Vector3(.92,.4,.62) if not big else Vector3(.84,.54,.86)
				crate(k,c,s,WOOD.lightened(.05*(i%3)))
				var top=c.y+s.y
				if lvl==rows-1 or (not big and lvl==1):
					if kind=="fish_crates":
						k.box(Vector3(c.x,top-.06,c.z),Vector3(s.x-.08,.04,s.z-.08),Color("dfeef4"),true) # ice
						for f in range(3):
							k.xf=Transform3D(Basis(Vector3.UP,.3*f),Vector3(c.x-.2+f*.2,top-.02,c.z));sphere(k,Vector3.ZERO,Vector3(.15,.035,.05),Color(["9fb8c4","c8d4dc","8a9aa4"][f]),6);k.xf=Transform3D()
					else:
						var fruit=[Color("e05a3a"),Color("f0c24f"),Color("8fbf5a"),Color("f09a3a"),Color("7a4fa0")][(absi(hs)+i)%5]
						for f in range(6):sphere(k,Vector3(c.x-.25+(f%3)*.25,top-.02,c.z-.12+(f/3)*.24),Vector3(.09,.08,.09),fruit,6)
			return AABB(Vector3(-1.05,0,-.4),Vector3(2.1,.9,.8)) if not big else AABB(Vector3(-.9,0,-.45),Vector3(1.75,1.7,1.))
		"desk":
			var top=[Color("c8a878"),Color("e8e4dc"),Color("6b4a32")][absi(hs)%3]
			k.box(Vector3(0,.74,0),Vector3(1.6,.05,.8),top,true)
			k.box(Vector3(.55,.36,0),Vector3(.45,.72,.75),top.darkened(.2),true) # drawer pedestal
			for i in range(3):k.box(Vector3(.55,.15+i*.22,.38),Vector3(.38,.18,.01),top.darkened(.1),true);k.box(Vector3(.55,.2+i*.22,.39),Vector3(.12,.02,.02),STEEL,true)
			k.box(Vector3(-.72,.36,0),Vector3(.05,.72,.75),top.darkened(.2),true)
			k.box(Vector3(-.1,.4,-.38),Vector3(1.2,.5,.02),top.darkened(.25),true) # modesty panel
			# monitor, keyboard, lamp
			k.box(Vector3(0,.78,-.22),Vector3(.24,.02,.16),IRON,true);k.box(Vector3(0,.88,-.24),Vector3(.04,.2,.03),IRON,true)
			P.cbox(k,Vector3(0,1.04,-.24),Vector3(.62,.38,.04),Color("1f2428"),.01)
			k.box(Vector3(0,1.04,-.218),Vector3(.56,.32,.006),Color("4fa8d8"),true)
			k.box(Vector3(0,.775,.05),Vector3(.45,.02,.15),Color("2a2f33"),true)
			k.box(Vector3(.33,.775,.08),Vector3(.06,.02,.09),Color("2a2f33"),true)
			P.cyl(k,Vector3(-.6,.765,-.2),Vector3(-.6,1.05,-.12),.012,STEEL,6)
			P.lathe(k,Vector3(-.6,.95,-.08),Basis(),[[0.,0.],[.1,0.],[.05,.1],[0.,.1]],Color("2f6f5a"),8)
			# office chair
			for i in range(5):
				var a=TAU*i/5.
				k.box(Vector3(cos(a)*.18,.05,.62+sin(a)*.18),Vector3(.36,.04,.05),IRON,true)
			P.cyl(k,Vector3(0,.05,.62),Vector3(0,.42,.62),.03,STEEL,6)
			P.cbox(k,Vector3(0,.46,.62),Vector3(.48,.08,.46),Color("2f3640"),.03)
			P.cbox(k,Vector3(0,.78,.84),Vector3(.44,.55,.06),Color("2f3640"),.03)
			return AABB(Vector3(-.8,0,-.4),Vector3(1.6,1.2,1.2))
		"woodplanks_stack":
			for i in range(4):
				var y=.03+i*.17
				for x in [-1.,0.,1.]:k.box(Vector3(x,y,0),Vector3(.08,.06,.95),WOOD.darkened(.25),true) # stickers
				for j in range(6):k.box(Vector3(0,y+.09,-.42+j*.168),Vector3(2.4-.04*(j%2),.06,.15),WOOD.lightened(.05*((i+j)%3)).darkened(.06*(i%2)),true)
			for x in [-.8,.8]:k.box(Vector3(x,.37,0),Vector3(.03,.72,.97),Color("3a5a8a"),true) # straps
			return AABB(Vector3(-1.2,0,-.45),Vector3(2.4,.7,1.))
		"pots":
			for i in range(3):
				var p=Vector3(-.5+i*.5,0,(i%2)*.18-.05);var r=.18+.04*(i%2)
				P.lathe(k,p,Basis(),[[0.,0.],[r*.75,0.],[r,.34],[r+.04,.36],[r+.04,.42],[r-.02,.42,Color("4a3628")],[0.,.4]],Color("b5634a").darkened(.05*i),12)
				if (absi(hs)+i)%3==0:
					for f in range(5):sphere(k,p+Vector3((f%3-1)*.08,.5+.05*(f/3),(f/3-.5)*.1),Vector3(.06,.05,.06),BLOOM[(absi(hs)+f+i)%BLOOM.size()],6)
					bush(k,p+Vector3(0,.4,0),.16,hs+i)
				else:bush(k,p+Vector3(0,.38,0),.22,hs+i)
			return AABB(Vector3(-.75,0,-.25),Vector3(1.5,.75,.7))
		"weapon_rack":
			k.box(Vector3(0,.1,0),Vector3(1.6,.2,.5),DARK_WOOD,true)
			for x in [-.75,.75]:k.box(Vector3(x,.75,-.18),Vector3(.1,1.4,.1),DARK_WOOD,true)
			k.box(Vector3(0,1.25,-.18),Vector3(1.6,.08,.12),DARK_WOOD.lightened(.1),true)
			k.box(Vector3(0,.55,-.12),Vector3(1.5,.06,.12),DARK_WOOD.lightened(.1),true)
			for i in range(4):
				var x=-.55+i*.37
				P.cyl(k,Vector3(x,.2,-.08),Vector3(x,1.45,-.12),.022,Color("7a5a3a"),6) # shafts
				if i%2==0:k.xf=Transform3D(Basis(),Vector3(x,1.45,-.12));P.lathe(k,Vector3.ZERO,Basis(),[[0.,0.],[.04,.0],[.06,.08],[0.,.26]],Color("b8c0c6"),4);k.xf=Transform3D() # spear head
				else:k.box(Vector3(x+.06,1.4,-.12),Vector3(.14,.2,.02),Color("b8c0c6"),true) # axe blade
			for x in [-.4,.4]:P.lathe(k,Vector3(x,.6,.05),Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[0.,0.],[.28,0.],[.3,.03],[.26,.05],[.06,.07,Color("c9a03a")],[0.,.08]],Color("8a3a2a") if x<0 else Color("2f4f7a"),12) # shields
			return AABB(Vector3(-.8,0,-.3),Vector3(1.6,1.5,.6))
		"ingots":
			var gold=absi(hs)%3==0
			var col=Color("e0b53a") if gold else Color("b8c0c6")
			for lvl in range(3):
				for i in range(3 if lvl<2 else 2):
					var x=-.5+i*.5+(.25 if lvl==2 else 0.)
					var along=lvl%2==0
					var c=Vector3(x,lvl*.15,0) if along else Vector3(0,lvl*.15,-.33+i*.33)
					k.xf=Transform3D(Basis(Vector3.UP,0. if along else PI*.5),c)
					P.extrude(k,P.pts([[-.2,0.],[.2,0.],[.16,.14],[-.16,.14]]),-.45,.45,col.darkened(.05*((i+lvl)%3)))
					k.xf=Transform3D()
			return AABB(Vector3(-.75,0,-.5),Vector3(1.5,.48,1.))
		"potting_bench":
			k.box(Vector3(0,.85,0),Vector3(1.8,.06,.7),WOOD,true)
			k.box(Vector3(0,.3,0),Vector3(1.7,.04,.6),WOOD.darkened(.1),true) # lower shelf
			for x in [-.82,.82]:
				for z in [-.28,.28]:k.box(Vector3(x,.42,z),Vector3(.07,.85,.07),DARK_WOOD,true)
			k.box(Vector3(0,1.05,-.33),Vector3(1.8,.4,.04),WOOD.darkened(.05),true) # back board
			for i in range(4):
				var p=Vector3(-.6+i*.4,.88,.05)
				P.lathe(k,p,Basis(),[[0.,0.],[.08,0.],[.11,.16],[.12,.18],[0.,.18]],Color("b5634a"),10)
				if i%2==0:bush(k,p+Vector3(0,.16,0),.13,hs+i)
				else:
					for f in range(3):sphere(k,p+Vector3((f-1)*.05,.24,0),Vector3(.045,.04,.045),BLOOM[(absi(hs)+i+f)%BLOOM.size()],6)
			# watering can and soil sack below
			P.lathe(k,Vector3(-.5,.32,.05),Basis(),[[0.,0.],[.12,0.],[.12,.2],[0.,.2]],Color("4f8a6a"),10)
			k.xf=Transform3D(Basis(Vector3.BACK,-.8),Vector3(-.36,.45,.05));P.cyl(k,Vector3.ZERO,Vector3(0,.22,0),.015,Color("4f8a6a"),6);k.xf=Transform3D()
			sack(k,Vector3(.4,.32,.05),Vector3(.5,.24,.34),Color("8a6a4a"))
			return AABB(Vector3(-.9,0,-.35),Vector3(1.8,1.,.7))
		"money_cart":
			k.box(Vector3(0,.5,0),Vector3(1.2,.06,.7),STEEL,true)
			k.box(Vector3(0,.2,0),Vector3(1.15,.04,.65),STEEL.darkened(.1),true)
			for x in [-.55,.55]:
				for z in [-.3,.3]:
					k.box(Vector3(x,.36,z),Vector3(.04,.36,.04),STEEL.darkened(.2),true)
					P.wheel(k,Vector3(x,.07,z),.07,.04,1.,IRON)
			P.cyl(k,Vector3(-.6,.5,-.3),Vector3(-.6,1.0,-.3),.02,STEEL,6);P.cyl(k,Vector3(-.6,.5,.3),Vector3(-.6,1.0,.3),.02,STEEL,6);P.cyl(k,Vector3(-.6,1.0,-.3),Vector3(-.6,1.0,.3),.02,STEEL,6)
			var bill=Color("7fb56a")
			for i in range(9):
				var x=-.4+(i%3)*.32;var y=.55+(i/3)*.11
				k.box(Vector3(x,y,((i%2)-.5)*.2),Vector3(.3,.1,.16),bill.darkened(.05*(i%2)),true)
				k.box(Vector3(x,y,((i%2)-.5)*.2),Vector3(.05,.102,.162),Color("e8dcb0"),true) # band
			sack(k,Vector3(.35,.77,.1),Vector3(.34,.26,.3),Color("6a5a40"))
			return AABB(Vector3(-.6,0,-.35),Vector3(1.2,1.1,.7))
		"deposit_block":
			var steel=Color("8a949c")
			P.cbox(k,Vector3(0,1.1,0),Vector3(1.8,2.2,.8),steel.darkened(.1),.03)
			for f in [1.,-1.]:
				for r in range(6):
					for i in range(5):
						var x=-.68+i*.34;var y=.28+r*.33
						var bw=.3;var bh=.29 if r>0 else .29
						k.box(Vector3(x,y,f*.405),Vector3(bw,bh,.012),Color("c9b27a") if (r+i)%7 else Color("b8a060"),true)
						k.box(Vector3(x+.09,y,f*.415),Vector3(.03,.03,.01),Color("4a4030"),true) # keyhole
						k.box(Vector3(x-.07,y+.08,f*.413),Vector3(.08,.03,.006),Color("efe8d2"),true) # number plate
			return AABB(Vector3(-.9,0,-.4),Vector3(1.8,2.2,.8))
		"cafe_table":
			P.lathe(k,Vector3.ZERO,Basis(),[[0.,0.],[.26,0.],[.26,.03],[.05,.06],[.04,.7],[.45,.71,Color("f1ece0")],[.47,.74],[0.,.75]],IRON,12)
			var seat=[Color("4f8f7a"),Color("b5563e"),Color("5a6f9a")][absi(hs)%3]
			for side in [-1.,1.]:
				var p=Vector3(side*.78,0,0)
				for dx in [-.15,.15]:
					for dz in [-.15,.15]:P.cyl(k,p+Vector3(dx,0,dz),p+Vector3(dx*.9,.44,dz*.9),.018,IRON,5)
				P.lathe(k,p+Vector3(0,.44,0),Basis(),[[0.,0.],[.2,0.],[.21,.04],[0.,.05]],seat,10)
				for i in range(3):k.box(p+Vector3(side*.18,.6+i*.12,(i-1)*.06),Vector3(.03,.1,.3),seat,true) # back
				k.box(p+Vector3(side*.19,.58,0),Vector3(.03,.3,.04),IRON,true)
			P.cyl(k,Vector3(0,.74,0),Vector3(0,2.45,0),.025,Color("e8e4da"),6)
			var stripe=[Color("d24c3f"),Color("2f7fbf"),Color("2f9a6a")][absi(hs)%3]
			for i in range(8):
				var a=TAU*i/8.;var b=TAU*(i+1)/8.
				var top=Vector3(0,2.65,0);var p=Vector3(cos(a)*1.25,2.2,sin(a)*1.25);var q=Vector3(cos(b)*1.25,2.2,sin(b)*1.25)
				var n=(q-p).cross(top-p).normalized()
				if n.y<0:n=-n
				P.tri(k,p,q,top,n,n,n,stripe if i%2==0 else Color("f4ead7"))
				P.tri(k,p,q,top,-n,-n,-n,stripe.darkened(.2) if i%2==0 else Color("d8cfbd"))
				P.quad(k,p,q,q+Vector3(0,-.12,0),p+Vector3(0,-.12,0),((p+q)*.5).normalized(),stripe if i%2 else Color("f4ead7"))
			return AABB(Vector3(-1.,0,-.5),Vector3(2.,.9,1.))
		"reading_table":
			var wood=Color("7a4a2e")
			k.box(Vector3(0,.76,0),Vector3(2.2,.06,1.),wood,true)
			k.box(Vector3(0,.68,0),Vector3(2.0,.1,.85),wood.darkened(.15),true) # apron
			for x in [-1.,1.]:
				for z in [-.4,.4]:P.lathe(k,Vector3(x,0,z),Basis(),[[0.,0.],[.05,0.],[.04,.15],[.06,.25],[.035,.4],[.045,.6],[.045,.73],[0.,.73]],wood.darkened(.1),8)
			for x in [-.6,.6]:
				k.box(Vector3(x,.8,-.25),Vector3(.18,.03,.12),Color("c9a24a"),true) # banker's lamp
				P.cyl(k,Vector3(x,.8,-.25),Vector3(x,1.05,-.25),.012,Color("c9a24a"),6)
				k.xf=Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(x,1.08,-.2));P.lathe(k,Vector3.ZERO,Basis(),[[0.,-.18],[.1,-.18],[.12,0.],[.1,.18],[0.,.18]],Color("2f6f4a"),8);k.xf=Transform3D()
				for i in range(2):k.box(Vector3(x+(i-.5)*.17,.8,.15),Vector3(.16,.03,.22),Color("f4ecd8"),true) # open book
				k.box(Vector3(x,.795,.15),Vector3(.34,.02,.24),Color("8a3a2a"),true)
			return AABB(Vector3(-1.1,0,-.5),Vector3(2.2,.9,1.))
		"fountain":
			# (1.4.6: the pool's water is a real water surface - DistrictProps adds it
			# over the tiled basin floor)
			var stone=Color("d6cbb5");var water=Color("b8e4ff")
			P.lathe(k,Vector3.ZERO,Basis(),[[0.,0.],[1.5,0.],[1.5,.45],[1.42,.5],[1.32,.5,stone.darkened(.1)],[1.3,.32],[0.,.32]],stone,20)
			P.lathe(k,Vector3(0,.33,0),Basis(),[[0.,0.],[1.3,0.],[0.,.0]],Color("9fc3cc"),20) # basin floor
			P.lathe(k,Vector3.ZERO,Basis(),[[0.,0.],[.32,0.],[.32,.2],[.22,.3],[.18,.6],[.22,.8],[.18,1.1],[.26,1.2],[0.,1.22]],stone.lightened(.05),12)
			P.lathe(k,Vector3(0,1.18,0),Basis(),[[0.,0.],[.12,0.],[.68,.14],[.72,.2],[.62,.22,water],[0.,.2]],stone,16)
			P.lathe(k,Vector3(0,1.38,0),Basis(),[[0.,0.],[.06,0.],[.04,.3],[.09,.36],[0.,.42]],stone,8)
			for i in range(6):
				var a=TAU*i/6.
				P.cyl(k,Vector3(cos(a)*.6,1.36,sin(a)*.6),Vector3(cos(a)*1.05,.45,sin(a)*1.05),.025,water.lightened(.3),4) # spouts
			return AABB(Vector3(-1.5,0,-1.5),Vector3(3.,1.,3.))
		"workbench":
			k.box(Vector3(0,.9,0),Vector3(2.,.08,.8),WOOD,true)
			for x in [-.92,.92]:
				for z in [-.33,.33]:k.box(Vector3(x,.45,z),Vector3(.07,.9,.07),STEEL.darkened(.25),true)
			k.box(Vector3(0,.25,0),Vector3(1.9,.04,.72),STEEL.darkened(.15),true)
			k.box(Vector3(.6,.6,.0),Vector3(.5,.5,.72),Color("c93f3f"),true) # drawer unit
			for i in range(3):k.box(Vector3(.6,.45+i*.15,.365),Vector3(.44,.12,.01),Color("b03636"),true);k.box(Vector3(.6,.48+i*.15,.375),Vector3(.15,.02,.02),STEEL,true)
			# bench vise, tools
			k.box(Vector3(-.75,.99,.32),Vector3(.18,.1,.16),Color("3f6f9f"),true);k.box(Vector3(-.75,1.06,.42),Vector3(.18,.08,.06),Color("3f6f9f"),true)
			P.cyl(k,Vector3(-.75,1.0,.48),Vector3(-.75,1.0,.62),.012,STEEL,6)
			k.box(Vector3(-.1,.955,-.1),Vector3(.35,.03,.05),STEEL,true);k.box(Vector3(.05,.96,.15),Vector3(.25,.04,.08),Color("e0a02f"),true)
			P.lathe(k,Vector3(.35,.94,-.2),Basis(),[[0.,0.],[.08,0.],[.08,.14],[0.,.14]],Color("2f6f9f"),8) # paint tin
			return AABB(Vector3(-1.,0,-.4),Vector3(2.,1.15,.8))
		"luggage":
			k.box(Vector3(0,.25,0),Vector3(1.4,.05,.7),STEEL,true)
			for x in [-.6,.6]:
				for z in [-.28,.28]:P.wheel(k,Vector3(x,.1,z),.1,.05,1.,IRON)
			P.cyl(k,Vector3(-.68,.25,-.3),Vector3(-.68,1.0,-.3),.02,STEEL,6);P.cyl(k,Vector3(-.68,.25,.3),Vector3(-.68,1.0,.3),.02,STEEL,6);P.cyl(k,Vector3(-.68,1.0,-.3),Vector3(-.68,1.0,.3),.02,STEEL,6)
			var bags=[Color("b5563e"),Color("3f5f8a"),Color("5a8a5a"),Color("2f2f33"),Color("c9a03a")]
			for i in range(3):
				var c=Vector3(-.35+i*.4,.28,0);var s=Vector3(.34,.5+.15*(i%2),.5)
				P.cbox(k,c+Vector3(0,s.y*.5,0),s,bags[(absi(hs)+i)%bags.size()],.05)
				k.box(c+Vector3(0,s.y+.03,0),Vector3(.04,.05,.18),IRON,true) # handle
				k.box(c+Vector3(0,s.y*.5,s.z*.5+.005),Vector3(s.x+.01,.04,.01),bags[(absi(hs)+i+2)%bags.size()].darkened(.2),true)
			return AABB(Vector3(-.7,0,-.35),Vector3(1.4,1.,.7))
		"tool_chest":
			var col=[Color("c93f3f"),Color("2f5f9f"),Color("3a3f45")][absi(hs)%3]
			P.cbox(k,Vector3(0,.58,0),Vector3(.96,.92,.52),col,.02)
			for i in range(6):
				var y=.2+i*.135
				k.box(Vector3(0,y,.262),Vector3(.88,.11,.01),col.darkened(.12),true)
				k.box(Vector3(0,y+.03,.272),Vector3(.5,.02,.02),Color("d8dcdf"),true)
			P.cbox(k,Vector3(0,1.1,0),Vector3(.98,.14,.54),col.lightened(.08),.03) # top box lid
			for x in [-.42,.42]:
				for z in [-.2,.2]:P.wheel(k,Vector3(x,.06,z),.06,.04,1.,IRON)
			k.box(Vector3(-.52,.7,0),Vector3(.04,.04,.4),Color("d8dcdf"),true) # side handle
			return AABB(Vector3(-.5,0,-.28),Vector3(1.,1.1,.56))
		"hay_bale":
			var straw=Color("e0c070")
			P.cbox(k,Vector3(0,.4,0),Vector3(1.4,.8,.9),straw,.08)
			for i in range(6):k.box(Vector3(0,.12+i*.12,0),Vector3(1.41,.03,.91),straw.darkened(.1),true) # straw layers
			for x in [-.35,.35]:k.box(Vector3(x,.4,0),Vector3(.03,.82,.92),Color("8a6a2a"),true) # twine
			k.xf=Transform3D(Basis(Vector3.UP,.25),Vector3(.25,.8,0))
			P.cbox(k,Vector3(0,.2,0),Vector3(1.1,.4,.75),straw.lightened(.05),.07)
			for x in [-.28,.28]:k.box(Vector3(x,.2,0),Vector3(.03,.42,.77),Color("8a6a2a"),true)
			k.xf=Transform3D()
			return AABB(Vector3(-.7,0,-.45),Vector3(1.4,1.2,.9))
		"globe":
			var wood=Color("6b4630")
			for i in range(3):
				var a=TAU*i/3.
				P.cyl(k,Vector3(cos(a)*.26,0,sin(a)*.26),Vector3(cos(a)*.08,.6,sin(a)*.08),.025,wood,6)
			P.lathe(k,Vector3(0,.55,0),Basis(),[[0.,0.],[.12,0.],[.1,.12],[0.,.14]],wood.lightened(.1),8)
			k.xf=Transform3D(Basis(Vector3.BACK,.41),Vector3(0,1.02,0))
			var prof=[];var rings=8
			for i in range(rings+1):
				var a=-PI*.5+PI*i/rings;prof.append([cos(a)*.27,sin(a)*.27,Color("4f86b8") if (i*3)%5 else Color("7fb56a")])
			prof[0][0]=0.;prof[rings][0]=0.
			P.lathe(k,Vector3.ZERO,Basis(),prof,Color("4f86b8"),14,false,.12)
			P.lathe(k,Vector3.ZERO,Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[.3,-.015],[.32,-.015],[.32,.015],[.3,.015]],Color("c9a24a"),18,true) # meridian
			k.xf=Transform3D()
			return AABB(Vector3(-.3,0,-.3),Vector3(.6,1.35,.6))
		"laundry":
			for x in [-1.3,1.3]:
				P.cyl(k,Vector3(x,0,0),Vector3(x,2.25,0),.06,DARK_WOOD,6)
				k.box(Vector3(x,2.2,0),Vector3(.3,.08,.1),DARK_WOOD,true)
			P.cyl(k,Vector3(-1.3,2.17,0),Vector3(1.3,2.12,0),.012,Color("d8d2c4"),4)
			var cloth=[Color("e8523f"),Color("5a88b8"),Color("f0c24f"),Color("f4f1e8"),Color("7fb56a")]
			for i in range(4):
				var x=-.9+i*.6;var h=[.6,.45,.7,.5][(absi(hs)+i)%4]
				P.quad(k,Vector3(x-.22,2.13-h,.01),Vector3(x+.22,2.13-h,-.01),Vector3(x+.22,2.13,-.01),Vector3(x-.22,2.13,.01),Vector3.BACK,cloth[(absi(hs)+i)%cloth.size()])
				P.quad(k,Vector3(x-.22,2.13-h,.01),Vector3(x+.22,2.13-h,-.01),Vector3(x+.22,2.13,-.01),Vector3(x-.22,2.13,.01),Vector3.FORWARD,cloth[(absi(hs)+i)%cloth.size()].darkened(.15))
				for px in [x-.18,x+.18]:k.box(Vector3(px,2.12,0),Vector3(.02,.07,.03),Color("8a6a4a"),true)
			return AABB(Vector3(-1.35,0,-.1),Vector3(2.7,.4,.2))
		"bike_rack":
			for i in range(4):
				var x=-.9+i*.6
				var prof=[]
				for j in range(9):prof.append(Vector3(x+cos(PI*j/8.)*.28,0. if j in [0,8] else .1+sin(PI*j/8.)*.6,0))
				for j in range(8):P.cyl(k,prof[j],prof[j+1],.025,Color("7a8288"),6)
				if (absi(hs)+i)%2==0:
					# a parked bicycle
					var bc=[Color("c93f3f"),Color("2f5f9f"),Color("3f8a5a")][(absi(hs)+i)%3]
					for side in [-.45,.45]:P.lathe(k,Vector3(x,.33,side),Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[.28,-.015],[.32,-.015],[.32,.015],[.28,.015]],IRON,12,true)
					P.cyl(k,Vector3(x,.33,-.45),Vector3(x,.6,0),.018,bc,5);P.cyl(k,Vector3(x,.6,0),Vector3(x,.33,.45),.018,bc,5);P.cyl(k,Vector3(x,.33,-.45),Vector3(x,.33,0),.018,bc,5)
					k.box(Vector3(x,.68,-.1),Vector3(.05,.04,.18),IRON,true)
			k.box(Vector3(0,.02,0),Vector3(2.2,.04,.1),Color("6a7278"),true)
			return AABB(Vector3(-1.2,0,-.2),Vector3(2.4,.7,.4))
		"well":
			var stone=Color("a9a08c")
			P.lathe(k,Vector3.ZERO,Basis(),[[0.,0.],[.9,0.],[.9,.75],[.95,.78],[.95,.85],[.72,.85,Color("2a3a44")],[.72,.6],[0.,.6]],stone,16,false,.06)
			for x in [-.82,.82]:k.box(Vector3(x,1.4,0),Vector3(.12,1.2,.12),DARK_WOOD,true)
			P.cyl(k,Vector3(-.82,1.55,0),Vector3(.82,1.55,0),.05,DARK_WOOD,6) # windlass
			k.box(Vector3(.9,1.45,0),Vector3(.04,.25,.04),DARK_WOOD,true)
			P.cyl(k,Vector3(0,1.55,0),Vector3(0,1.05,0),.01,Color("c9b27a"),4)
			P.lathe(k,Vector3(0,.88,0),Basis(),[[0.,0.],[.13,0.],[.16,.2],[0.,.2]],Color("7a5a3a"),8) # bucket
			for side in [-1.,1.]:
				k.xf=Transform3D(Basis(Vector3.RIGHT,side*.55),Vector3(0,2.08,side*.25))
				k.box(Vector3.ZERO,Vector3(1.95,.06,.62),Color("b5563e").darkened(.05*(side+1.)),true)
				k.xf=Transform3D()
			return AABB(Vector3(-.9,0,-.9),Vector3(1.8,.9,1.8))
		"target_stand":
			for x in [-.5,.5]:k.box(Vector3(x,.85,0),Vector3(.08,1.7,.08),DARK_WOOD,true)
			k.box(Vector3(0,.4,0),Vector3(1.3,.8,.5),Color("b8a47a"),true) # sand-filled base
			for i in range(3):k.box(Vector3(0,.15+i*.25,.255),Vector3(1.3,.02,.01),Color("8a7a5a"),true)
			k.box(Vector3(0,1.32,0),Vector3(1.1,.95,.04),Color("f4f1e8"),true)
			for f in [1.,-1.]:
				var z=f*.025
				k.xf=Transform3D(Basis(Vector3.UP,0. if f>0 else PI),Vector3(0,1.32,z))
				k.disc(Vector3(0,0,.002),.38,Color("2a2a2a"),14);k.disc(Vector3(0,0,.004),.28,Color("f4f1e8"),14);k.disc(Vector3(0,0,.006),.17,Color("e05a3a"),12);k.disc(Vector3(0,0,.008),.06,Color("f0c24f"),8)
				k.xf=Transform3D()
			return AABB(Vector3(-.65,0,-.25),Vector3(1.3,1.8,.5))
		# --- new themed pieces -------------------------------------------------
		"ammo_crates":
			var g=Color("5a6a3a")
			for i in range(6):
				var lvl=i/2 if i<4 else i-2;var col=i%2
				var c=Vector3(-.42+col*.85,lvl*.42,0) if i<4 else Vector3(-.36,lvl*.42,.02*(i%2))
				P.cbox(k,c+Vector3(0,.2,0),Vector3(.82,.4,.9),g.darkened(.05*(i%3)),.02)
				for x in [-.3,.3]:k.box(c+Vector3(x,.2,0),Vector3(.06,.41,.91),g.darkened(.2),true) # rope beckets
				k.box(c+Vector3(0,.25,.452),Vector3(.4,.1,.005),Color("e0d8a0"),true) # stencil
				k.box(c+Vector3(.33,.36,.44),Vector3(.06,.06,.03),IRON,true) # latch
			return AABB(Vector3(-.9,0,-.45),Vector3(1.75,1.7,1.))
		"equipment_cases":
			var shells=[Color("2f3438"),Color("c9a03a"),Color("3f5f7a")]
			var spots=[[Vector3(-.42,0,0),Vector3(.85,.55,.95)],[Vector3(.45,0,.05),Vector3(.75,.5,.85)],[Vector3(-.35,.55,0),Vector3(.8,.45,.8)],[Vector3(.4,.5,0),Vector3(.65,.35,.6)],[Vector3(-.3,1.0,.05),Vector3(.6,.3,.55)],[Vector3(-.28,1.3,0),Vector3(.55,.32,.5)]]
			for i in range(spots.size()):
				var c:Vector3=spots[i][0];var s:Vector3=spots[i][1];var col=shells[(absi(hs)+i)%shells.size()]
				P.cbox(k,c+Vector3(0,s.y*.5,0),s,col,.05)
				k.box(c+Vector3(0,s.y*.55,0),Vector3(s.x+.01,.03,s.z+.01),col.darkened(.25),true) # seam
				for x in [-s.x*.3,s.x*.3]:k.box(c+Vector3(x,s.y*.55,s.z*.5+.012),Vector3(.08,.06,.02),STEEL,true) # latches
				k.box(c+Vector3(0,s.y+.02,0),Vector3(.22,.04,.05),IRON,true) # handle
			return AABB(Vector3(-.9,0,-.45),Vector3(1.75,1.7,1.))
		"sack_stack","sack_pallet":
			var tall=kind=="sack_stack"
			var cols=[Color("d8c49a"),Color("c9b07a"),Color("e6dcc0"),Color("a89068")]
			if not tall:pallet(k,Vector3.ZERO,Vector3(1.3,0,1.1))
			var base=.14 if not tall else 0.
			var layers=4 if not tall else 6
			for l in range(layers):
				for i in range(2):
					var along=l%2==0
					var c=Vector3((i-.5)*.55 if along else 0.,base+l*.26,0. if along else (i-.5)*.45)
					sack(k,c,Vector3(.52 if along else 1.0,.28,.95 if along else .42),cols[(absi(hs)+l+i)%cols.size()],0. if along else 0.)
				if tall and l>=4:break
			return AABB(Vector3(-.9,0,-.45),Vector3(1.75,1.7,1.)) if tall else AABB(Vector3(-.65,0,-.55),Vector3(1.3,1.16,1.1))
		"lobster_pots":
			for i in range(5):
				var lvl=i/2;var col=i%2
				var c=Vector3(-.42+col*.85,lvl*.55,0) if lvl<2 else Vector3(0,1.1,.05)
				var s=Vector3(.8,.53,.9)
				# cage: frame bars and netting
				for sx in [-1.,1.]:
					for sz in [-1.,1.]:k.box(c+Vector3(sx*s.x*.48,s.y*.5,sz*s.z*.48),Vector3(.03,s.y,.03),Color("4a5a3a"),true)
				for y in [.02,s.y-.02]:
					k.box(c+Vector3(0,y,s.z*.48),Vector3(s.x,.03,.03),Color("4a5a3a"),true);k.box(c+Vector3(0,y,-s.z*.48),Vector3(s.x,.03,.03),Color("4a5a3a"),true)
					k.box(c+Vector3(s.x*.48,y,0),Vector3(.03,.03,s.z),Color("4a5a3a"),true);k.box(c+Vector3(-s.x*.48,y,0),Vector3(.03,.03,s.z),Color("4a5a3a"),true)
				for j in range(5):k.box(c+Vector3(-s.x*.4+j*s.x*.2,s.y*.5,0),Vector3(.012,s.y,s.z),Color("6a7a5a"),true) # netting
				k.box(c+Vector3(0,s.y*.5,0),Vector3(s.x*.8,s.y*.6,s.z*.8),Color("7a6a4a"),true) # bait bag / net inside
				if i==4:sphere(k,c+Vector3(.3,s.y+.12,0),Vector3(.13,.13,.13),Color("e8523f"),8) # buoy
			return AABB(Vector3(-.9,0,-.45),Vector3(1.75,1.7,1.))
		"drum_pallet":
			pallet(k,Vector3.ZERO,Vector3(1.3,0,1.1))
			var dc=[Color("3f7fbf"),Color("c9503a"),Color("e0b83a"),Color("4f8a5a")]
			for i in range(4):drum_at(k,Vector3(-.31+(i%2)*.62,.14,-.27+(i/2)*.54),dc[(absi(hs)+i/2)%dc.size()],(absi(hs)+i)%3==0,.27,.88)
			return AABB(Vector3(-.65,0,-.55),Vector3(1.3,1.16,1.1))
		"brick_pallet":
			pallet(k,Vector3.ZERO,Vector3(1.3,0,1.1))
			var brick=[Color("b5563e"),Color("a8483a"),Color("c46a4a")][absi(hs)%3]
			for l in range(7):
				for i in range(4):
					var along=l%2==0
					var c=Vector3(-.45+i*.3,.18+l*.12,0) if along else Vector3(0,.18+l*.12,-.4+i*.27)
					k.box(c,Vector3(.28,.11,1.0) if along else Vector3(1.2,.11,.25),brick.darkened(.04*((l+i)%3)),true)
			for x in [-.3,.3]:k.box(Vector3(x,.6,0),Vector3(.03,.88,1.03),Color("2f2f2f"),true)
			return AABB(Vector3(-.65,0,-.55),Vector3(1.3,1.16,1.1))
		"water_barrels":
			var blue=Color("2f6fb8")
			for i in range(4):
				var p=Vector3(-.32+(i%2)*.64,0,-.26+(i/2)*.52)
				P.lathe(k,p,Basis(),[[0.,0.],[.26,0.],[.29,.05],[.29,.3,blue.darkened(.15)],[.3,.33],[.29,.36,blue],[.29,.72,blue.darkened(.15)],[.3,.75],[.29,.78,blue],[.29,.95],[.24,1.0],[0.,1.0]],blue,12)
				P.cyl(k,p+Vector3(.1,1.0,0),p+Vector3(.1,1.04,0),.05,Color("e8e4da"),6)
			return AABB(Vector3(-.65,0,-.55),Vector3(1.3,1.16,1.1))
		"generator":
			var y=Color("e0a02f") if absi(hs)%2==0 else Color("3f7a52")
			k.box(Vector3(0,.08,0),Vector3(1.25,.16,.9),IRON,true)
			P.cbox(k,Vector3(0,.6,0),Vector3(1.2,.9,.85),y,.05)
			for f in [1.,-1.]:
				for i in range(6):k.box(Vector3(-.35+i*.1,.65,f*.43),Vector3(.05,.4,.01),y.darkened(.3),true) # louvres
				k.box(Vector3(.35,.7,f*.43),Vector3(.28,.2,.01),Color("2a2f33"),true) # control panel
				k.box(Vector3(.3,.72,f*.437),Vector3(.05,.05,.006),Color("3fe07a"),true)
			P.cyl(k,Vector3(-.4,1.05,.2),Vector3(-.4,1.15,.2),.05,IRON,8) # exhaust
			k.box(Vector3(0,1.07,0),Vector3(.9,.04,.1),IRON,true) # lifting bar
			for x in [-.5,.5]:P.wheel(k,Vector3(x,.12,.46),.12,.06,1.,IRON)
			return AABB(Vector3(-.65,0,-.55),Vector3(1.3,1.16,1.1))
		"milk_churns":
			for i in range(5):
				var p=Vector3(-.55+(i%3)*.55,0,-.3+(i/3)*.55+.1*(i%2))
				P.lathe(k,p,Basis(),[[0.,0.],[.2,0.],[.21,.04],[.21,.5,Color("b8c0c6")],[.2,.55],[.12,.68],[.12,.78,Color("9aa4aa")],[.15,.8],[.15,.86],[0.,.88]],Color("c8d0d6"),12)
				for side in [-1.,1.]:k.box(p+Vector3(side*.22,.58,0),Vector3(.03,.08,.08),STEEL,true)
			return AABB(Vector3(-.85,0,-.6),Vector3(1.7,.95,1.4))
		"vending_machine":
			var col=[Color("c93f3f"),Color("2f6fb8"),Color("2f8a5a")][absi(hs)%3]
			P.cbox(k,Vector3(0,.95,0),Vector3(.95,1.9,.75),col,.03)
			k.box(Vector3(-.12,1.15,.376),Vector3(.6,1.1,.01),Color("1f2a33"),true) # window
			for r in range(5):
				for c in range(4):sphere(k,Vector3(-.36+c*.16,.72+r*.22,.33),Vector3(.04,.07,.04),[Color("e05a3a"),Color("f0c24f"),Color("4fa8d8"),Color("8fbf5a")][(r+c+absi(hs))%4],5)
			k.box(Vector3(.33,1.25,.38),Vector3(.18,.5,.01),Color("2a2f33"),true) # keypad
			k.box(Vector3(-.12,.35,.38),Vector3(.55,.18,.02),Color("1f2428"),true) # drawer
			k.box(Vector3(0,1.8,.376),Vector3(.9,.18,.01),Color("f4f1e8"),true) # brand strip
			return AABB(Vector3(-.5,0,-.4),Vector3(1.,1.9,.8))
		"phone_booth":
			var col=Color("c93f3f") if absi(hs)%2==0 else Color("2f6fb8")
			P.cbox(k,Vector3(0,.06,0),Vector3(.95,.12,.95),IRON,.02)
			for sx in [-1.,1.]:
				for sz in [-1.,1.]:k.box(Vector3(sx*.42,1.15,sz*.42),Vector3(.08,2.1,.08),col,true)
			P.cbox(k,Vector3(0,2.25,0),Vector3(1.0,.22,1.0),col,.06)
			k.box(Vector3(0,2.25,.505),Vector3(.6,.12,.01),Color("f4f1e8"),true)
			for f in [Vector3.BACK,Vector3.FORWARD,Vector3.RIGHT]:
				var c=f*.42+Vector3(0,1.25,0)
				var ex=Vector3(-f.z,0,f.x)*.38
				P.quad(k,c-ex-Vector3(0,.8,0),c+ex-Vector3(0,.8,0),c+ex+Vector3(0,.8,0),c-ex+Vector3(0,.8,0),f,Color("9fc4d4"))
				for j in range(4):k.box(c+Vector3(0,-.8+j*.53,0),Vector3(.76 if f.x==0 else .04,.04,.04 if f.x==0 else .76),col,true)
			k.box(Vector3(-.3,1.3,0),Vector3(.12,.35,.25),Color("2a2f33"),true) # phone
			return AABB(Vector3(-.5,0,-.5),Vector3(1.,2.4,1.))
		"wheelie_bins":
			var cols=[Color("3f7a52"),Color("2f5f9f"),Color("6a7078"),Color("c9a03a")]
			for i in range(2):
				var p=Vector3(-.36+i*.72,0,0);var col=cols[(absi(hs)+i)%cols.size()]
				k.xf=Transform3D(Basis(),p)
				P.extrude(k,P.pts([[-.32,.05],[.32,.05],[.36,1.0],[-.36,1.0]]),-.32,.32,col)
				k.box(Vector3(0,1.04,.02),Vector3(.76,.06,.72),col.darkened(.15),true) # lid
				k.box(Vector3(0,1.0,-.36),Vector3(.5,.04,.05),col.darkened(.25),true) # handle
				for x in [-.25,.25]:P.wheel(k,Vector3(x,.1,-.3),.1,.06,1. if x>0 else -1.,IRON)
				k.xf=Transform3D()
			return AABB(Vector3(-.75,0,-.4),Vector3(1.5,1.1,.8))
		"notice_board":
			for x in [-.75,.75]:P.cyl(k,Vector3(x,0,0),Vector3(x,2.0,0),.05,DARK_WOOD,6)
			k.box(Vector3(0,1.4,0),Vector3(1.6,1.0,.08),DARK_WOOD,true)
			for f in [1.,-1.]:
				k.box(Vector3(0,1.4,f*.042),Vector3(1.45,.88,.005),Color("b88a5a"),true) # cork
				for i in range(6):
					var c=Vector3(-.55+(i%3)*.5,1.2+(i/3)*.4,f*.047)
					k.box(c,Vector3(.3,.24,.004),[Color("f4f1e8"),Color("f0e0a0"),Color("d8e8f4"),Color("f4d8d8")][(absi(hs)+i)%4],true)
			k.xf=Transform3D(Basis(Vector3.RIGHT,.0),Vector3.ZERO)
			for side in [-1.,1.]:k.xf=Transform3D(Basis(Vector3.RIGHT,side*.5),Vector3(0,2.02,side*.12));k.box(Vector3.ZERO,Vector3(1.75,.04,.3),Color("8a4a3a"),true)
			k.xf=Transform3D()
			return AABB(Vector3(-.85,0,-.2),Vector3(1.7,2.1,.4))
		"mailbox":
			var col=Color("c93f3f") if absi(hs)%2==0 else Color("2f5f9f")
			P.lathe(k,Vector3.ZERO,Basis(),[[0.,0.],[.28,0.],[.28,.1],[.24,.12],[.24,1.15],[.27,1.2],[.2,1.32],[0.,1.36]],col,14)
			k.box(Vector3(0,1.0,.24),Vector3(.26,.05,.04),Color("2a2a2a"),true) # slot
			k.box(Vector3(0,.7,.245),Vector3(.18,.14,.006),Color("f4f1e8"),true)
			return AABB(Vector3(-.3,0,-.3),Vector3(.6,1.36,.6))
		"fire_hydrant":
			var col=Color("c93f3f") if absi(hs)%3 else Color("e0b53a")
			P.lathe(k,Vector3.ZERO,Basis(),[[0.,0.],[.2,0.],[.2,.06],[.14,.1],[.13,.5],[.16,.55],[.16,.6],[.1,.68],[.04,.75],[0.,.76]],col,12)
			for side in [-1.,1.]:P.cyl(k,Vector3(side*.12,.42,0),Vector3(side*.24,.42,0),.055,col.darkened(.1),8)
			P.cyl(k,Vector3(0,.42,.12),Vector3(0,.42,.22),.07,col.darkened(.1),8)
			return AABB(Vector3(-.26,0,-.24),Vector3(.52,.76,.48))
		"statue":
			var stone=Color("c9c2b0")
			P.cbox(k,Vector3(0,.5,0),Vector3(1.1,1.0,1.1),CONCRETE,.05)
			k.box(Vector3(0,1.02,0),Vector3(1.2,.06,1.2),CONCRETE.lightened(.08),true)
			k.box(Vector3(0,.55,.555),Vector3(.6,.18,.01),Color("8a7a50"),true) # plaque
			# figure: legs, coat, torso, head, raised arm
			for x in [-.1,.1]:P.cyl(k,Vector3(x,1.05,0),Vector3(x,1.6,0),.07,stone.darkened(.05),6)
			P.lathe(k,Vector3(0,1.35,0),Basis(),[[0.,0.],[.28,0.],[.22,.5],[.18,.8],[0.,.82]],stone,8)
			sphere(k,Vector3(0,2.3,0),Vector3(.13,.15,.13),stone,8)
			P.cyl(k,Vector3(.2,2.05,0),Vector3(.42,2.45,.05),.05,stone,6)
			P.cyl(k,Vector3(-.2,2.05,0),Vector3(-.28,1.65,.08),.05,stone,6)
			return AABB(Vector3(-.6,0,-.6),Vector3(1.2,2.6,1.2))
		"net_rack":
			for x in [-.9,.9]:P.cyl(k,Vector3(x,0,0),Vector3(x,1.8,0),.05,DARK_WOOD,6)
			P.cyl(k,Vector3(-.95,1.75,0),Vector3(.95,1.75,0),.04,DARK_WOOD,6)
			var net=Color("5a7a6a")
			for i in range(5):
				var x0=-.8+i*.32
				P.quad(k,Vector3(x0,.5+.1*(i%2),.03),Vector3(x0+.34,.6,.0),Vector3(x0+.34,1.74,0.),Vector3(x0,1.74,.02),Vector3.BACK,net.darkened(.05*(i%3)))
				P.quad(k,Vector3(x0,.5+.1*(i%2),.03),Vector3(x0+.34,.6,.0),Vector3(x0+.34,1.74,0.),Vector3(x0,1.74,.02),Vector3.FORWARD,net.darkened(.15))
			for i in range(3):sphere(k,Vector3(-.5+i*.5,.55,.05),Vector3(.1,.1,.1),Color("e8a03a") if i%2 else Color("e8523f"),6) # floats
			return AABB(Vector3(-1.,0,-.25),Vector3(2.,1.8,.5))
		"compressor":
			var col=Color("c93f3f") if absi(hs)%2 else Color("2f6fb8")
			k.xf=Transform3D(Basis(Vector3.BACK,PI*.5),Vector3(0,.42,0))
			P.lathe(k,Vector3(0,-.6,0),Basis(),[[0.,0.],[.2,.02],[.28,.12],[.28,1.08],[.2,1.18],[0.,1.2]],col,12)
			k.xf=Transform3D()
			k.box(Vector3(.1,.82,0),Vector3(.5,.24,.36),IRON,true) # motor
			P.lathe(k,Vector3(-.3,.7,0),Basis(),[[0.,0.],[.06,0.],[.06,.18],[0.,.18]],Color("2a2f33"),8) # pump
			k.box(Vector3(.45,.8,.2),Vector3(.12,.12,.02),Color("f4f1e8"),true) # gauge
			for x in [-.5,.5]:P.wheel(k,Vector3(x,.12,.2),.12,.05,1.,IRON)
			k.box(Vector3(-.6,.16,0),Vector3(.06,.32,.3),IRON,true)
			return AABB(Vector3(-.7,0,-.3),Vector3(1.4,1.,.6))
		"wheelbarrow":
			var col=Color("3f7a52") if absi(hs)%2==0 else Color("c93f3f")
			k.xf=Transform3D(Basis(Vector3.BACK,-.12),Vector3(0,.32,0))
			P.extrude(k,P.pts([[-.45,0.],[.35,0.],[.5,.35],[-.6,.35]]),-.3,.3,col)
			k.xf=Transform3D()
			P.wheel(k,Vector3(.65,.18,0),.18,.08,1.,IRON)
			for z in [-.22,.22]:P.cyl(k,Vector3(.6,.18,z*.4),Vector3(-.95,.5,z),.02,DARK_WOOD,5);k.box(Vector3(-.5,.15,z),Vector3(.04,.3,.04),IRON,true)
			if absi(hs)%3==0:for i in range(4):rock(k,Vector3(-.1+i*.12,.55,(i%2-.5)*.2),Vector3(.18,.14,.16),CONCRETE,hs+i)
			else:sphere(k,Vector3(-.05,.62,0),Vector3(.4,.12,.25),Color("6a4a32"),8) # soil
			return AABB(Vector3(-1.,0,-.35),Vector3(1.85,.8,.7))
		"flower_cart":
			k.box(Vector3(0,.7,0),Vector3(1.6,.1,.8),WOOD,true)
			for x in [-.75,.75]:k.box(Vector3(x,.55,0),Vector3(.06,.3,.8),WOOD.darkened(.1),true)
			for side in [-.42,.42]:P.wheel(k,Vector3(.4,.35,side),.35,.06,1. if side>0 else -1.,DARK_WOOD)
			k.box(Vector3(-.6,.35,0),Vector3(.06,.7,.06),DARK_WOOD,true)
			P.cyl(k,Vector3(-.8,.75,-.3),Vector3(-1.2,.65,-.3),.025,DARK_WOOD,5);P.cyl(k,Vector3(-.8,.75,.3),Vector3(-1.2,.65,.3),.025,DARK_WOOD,5)
			for i in range(6):
				var p=Vector3(-.55+(i%3)*.5,.75,-.2+(i/3)*.4)
				P.lathe(k,p,Basis(),[[0.,0.],[.14,0.],[.16,.18],[0.,.18]],[Color("5a7aa0"),Color("b5634a"),Color("e8e4da")][i%3],8)
				for f in range(5):sphere(k,p+Vector3((f%3-1)*.06,.24+.05*(f/3),(f/3-.5)*.08),Vector3(.05,.045,.05),BLOOM[(absi(hs)+i+f)%BLOOM.size()],6)
			for i in range(5):
				P.quad(k,Vector3(-.8+i*.32,1.65,-.45),Vector3(-.48+i*.32,1.65,-.45),Vector3(-.48+i*.32,1.8,.45),Vector3(-.8+i*.32,1.8,.45),Vector3.UP,Color("e8c84a") if i%2 else Color("f4f1e8"))
			for x in [-.75,.75]:P.cyl(k,Vector3(x,.75,.38),Vector3(x,1.8,.42),.02,DARK_WOOD,5)
			return AABB(Vector3(-1.2,0,-.45),Vector3(2.,1.8,.9))
		"warning_sign":
			# 1.5.0 (the user): a triangular drowning warning - a black-rimmed yellow
			# triangle, a figure with both arms up over three wavy lines - on the front
			# (+z, the walkway side); the post stands behind the panel; no text plate.
			var ink=Color("1f2428");var yellow=Color("f2c230")
			P.cyl(k,Vector3(0,0,-.045),Vector3(0,1.98,-.045),.035,Color("6a7278"),8)
			var tri_plate=func(base:float,side:float,z0:float,z1:float,col:Color):
				var hgt=side*.866;var pts=[Vector3(-side*.5,base,0),Vector3(side*.5,base,0),Vector3(0,base+hgt,0)]
				P.tri(k,pts[0]+Vector3(0,0,z1),pts[1]+Vector3(0,0,z1),pts[2]+Vector3(0,0,z1),Vector3.BACK,Vector3.BACK,Vector3.BACK,col)
				P.tri(k,pts[0]+Vector3(0,0,z0),pts[1]+Vector3(0,0,z0),pts[2]+Vector3(0,0,z0),Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD,col)
				for e in range(3):
					var p0:Vector3=pts[e];var p1:Vector3=pts[(e+1)%3];var out=(p1-p0).cross(Vector3.BACK).normalized()
					P.quad(k,p0+Vector3(0,0,z0),p1+Vector3(0,0,z0),p1+Vector3(0,0,z1),p0+Vector3(0,0,z1),out,col)
			tri_plate.call(1.38,.80,-.01,.02,ink) # rim (the panel itself)
			tri_plate.call(1.425,.66,.02,.024,yellow) # face
			tri_plate.call(1.425,.66,-.014,-.01,yellow) # back face (seen from the water side)
			var z=.027
			k.disc(Vector3(0,1.75,z),.038,ink,10) # head
			k.box(Vector3(0,1.655,z),Vector3(.05,.1,.004),ink,true) # body rising from the water
			for s in [-1.,1.]:
				var sh=Vector3(s*.022,1.69,z);var hand=Vector3(s*.095,1.81,z);var across=(hand-sh).cross(Vector3.BACK).normalized()*.012
				P.quad(k,sh-across,hand-across,hand+across,sh+across,Vector3.BACK,ink) # arms up
			for row in range(3):
				var y=1.47+row*.045;var half=.2-row*.025;var n=10
				for i in range(n):
					var x0=-half+2.*half*i/n;var x1=-half+2.*half*(i+1)/n
					var y0=y+sin(x0*38.)*.011;var y1=y+sin(x1*38.)*.011
					P.quad(k,Vector3(x0,y0-.008,z),Vector3(x1,y1-.008,z),Vector3(x1,y1+.008,z),Vector3(x0,y0+.008,z),Vector3.BACK,ink) # a wavy line
			return AABB(Vector3(-.41,0,-.08),Vector3(.82,2.08,.13))
		"lifebuoy_stand":
			P.cyl(k,Vector3.ZERO,Vector3(0,1.5,0),.05,Color("c93f3f"),8)
			P.cbox(k,Vector3(0,1.15,-.06),Vector3(.7,.75,.08),Color("c93f3f"),.02) # backboard
			k.box(Vector3(0,1.5,-.02),Vector3(.74,.06,.18),Color("a83232"),true) # hood
			var ring=Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK))
			P.lathe(k,Vector3(0,1.1,0),ring,[[.18,-.06],[.22,-.08],[.29,-.08],[.33,-.04],[.33,.04],[.29,.08],[.22,.08],[.18,.06]],Color("f08a2e"),16,true,0.)
			for i in range(4):
				var a=TAU*i/4.+PI*.25
				k.box(Vector3(cos(a)*.255,1.1+sin(a)*.255,0),Vector3(.1,.1,.17),Color("f4f4f0"),true) # white bands
			P.lathe(k,Vector3(0,.55,-.06),Basis(),[[.0,0.],[.13,0.],[.13,.18],[0.,.18]],Color("e8d8a0"),10,false,.15) # rope coil
			return AABB(Vector3(-.38,0,-.12),Vector3(.76,1.55,.3))
	return AABB()
## Collision shapes for the new pieces whose box would hide a gap (others
## keep DistrictProps' rules or their footprint box).
static func collision(kind:String,occupied:AABB) -> Array:
	match kind:
		"water_barrels","milk_churns":
			var out=[]
			if kind=="water_barrels":
				for i in range(4):out.append(DistrictProps.cylinder(Vector3(-.32+(i%2)*.64,0,-.26+(i/2)*.52),.3,1.0))
			else:
				for i in range(5):out.append(DistrictProps.cylinder(Vector3(-.55+(i%3)*.55,0,-.3+(i/3)*.55+.1*(i%2)),.21,.88))
			return out
		"mailbox":return [DistrictProps.cylinder(Vector3.ZERO,.28,1.36)]
		"fire_hydrant":return [DistrictProps.cylinder(Vector3.ZERO,.2,.76)]
		"notice_board","net_rack":return [DistrictProps.block(Vector3(occupied.position.x,0,-.06),Vector3(occupied.end.x,occupied.end.y,.06))]
	return []
