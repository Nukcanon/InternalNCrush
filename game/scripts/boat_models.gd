class_name BoatModels
extends RefCounted
## 1.4.6 (the user): new boats - several kinds that suit their maps - moored
## in deep water beside a quay. They are part of the map: the deck is flush
## with the quay (players walk aboard where the quay parapet is open), the
## cabins are solid cover. Local frame: water line at y=0, length along X (bow
## at +X), beam along Z; `gap` is the side (+1: +Z) facing the quay, where the
## bulwark opens amidships.
const P=preload("res://scripts/prop_models.gd")
const DECK=.75 # deck above the water line: flush with a quay at 0 over water at -0.7 (+.05)
const SIZES={"narrowboat":Vector2(11.,2.3),"houseboat":Vector2(9.,3.4),"launch":Vector2(6.5,2.4),"fishing":Vector2(9.,3.2),"tug":Vector2(8.,3.4),
	"lighter":Vector2(12.,4.2),"patrol":Vector2(9.5,3.),"workboat":Vector2(6.,2.4),"wreck":Vector2(9.,3.2),"punt":Vector2(4.5,1.5),
	# 1.5.4 (the user: boats far bigger - people walk about inside them): walk-in deckhouses
	"ferry":Vector2(20.,6.),"freighter":Vector2(24.,7.),"trawler":Vector2(15.,5.),"barge":Vector2(18.,4.6)}
const WOOD=Color("9a6a42")
const GLASS=Color("2f4656")
const DARK=Color("2a3036")
const WHITE=Color("eef0ea")
## Builds the boat into `k`; returns collision parts [[Shape3D, Transform3D]].
static func build(k:DistrictFacade.Kit,kind:String,hs:int,gap:int) -> Array:
	var size:Vector2=SIZES.get(kind,Vector2(6.,2.4));var L=size.x;var B=size.y
	var shapes=[]
	var palettes={"narrowboat":[[Color("2f6a4a"),Color("b8403a")],[Color("8a2f3a"),Color("2f4f7a")],[Color("1f3f6a"),Color("c9a03a")]],
		"houseboat":[[Color("e8e4da"),Color("3f7fbf")],[Color("d9b45a"),Color("5a7a5a")]],"launch":[[WHITE,Color("2f5f9f")],[Color("c9503a"),WHITE]],
		"fishing":[[Color("2f5f9f"),Color("e8523f")],[Color("e8a03a"),Color("2f3f5a")]],"tug":[[Color("c93f3f"),Color("2a3036")],[Color("2a3036"),Color("e0b53a")]],
		"lighter":[[Color("4a5866"),Color("c9a03a")],[Color("7a4a3a"),Color("2a3036")]],"patrol":[[Color("7f8a92"),Color("2a3036")]],
		"workboat":[[Color("e0b53a"),Color("2a3036")],[Color("3f7a52"),WHITE]],"wreck":[[Color("6a4a3a"),Color("5a6a6a")]],"punt":[[WOOD,DARK]],
		"ferry":[[WHITE,Color("2f5f9f")],[WHITE,Color("c9503a")]],"freighter":[[Color("2f4f6f"),Color("c9503a")],[Color("5a3a2f"),Color("e0b53a")]],
		"trawler":[[Color("2f6f9f"),Color("e8523f")],[Color("e8a03a"),Color("2f3f5a")]],"barge":[[Color("3f4a52"),Color("e0b53a")],[Color("6a3a2f"),Color("d8d4c4")]]}
	var pal:Array=palettes.get(kind,[[WHITE,DARK]])[absi(hs)%palettes.get(kind,[[WHITE,DARK]]).size()]
	var hull_col:Color=pal[0];var trim:Color=pal[1]
	var draft=.55 if kind=="punt" else .9
	var bow=L*(.12 if kind in ["lighter","punt","narrowboat","barge"] else .2 if kind in ["ferry","freighter"] else .28)
	hull(k,L,B,DECK,draft,bow,hull_col if kind!="wreck" else Color("6a4a3a"),trim,kind in ["lighter","punt","barge"])
	var deck_col=WOOD if kind in ["narrowboat","houseboat","punt","fishing"] else Color("8a9298") if kind in ["patrol","tug","workboat"] else Color("6f6a5f")
	var outline=plan(L,B,bow,kind in ["lighter","punt","barge"])
	deck(k,outline,DECK,deck_col)
	# walkable deck: the plan outline as one convex slab
	var pts=PackedVector3Array()
	for p in outline:pts.append(Vector3(p.x,DECK,p.y));pts.append(Vector3(p.x,-.6,p.y))
	var hull_shape=ConvexPolygonShape3D.new();hull_shape.points=pts;shapes.append([hull_shape,Transform3D()])
	# bulwarks (rails) round the deck, open amidships on the quay side
	var rail_h=.9 if kind!="punt" else .25
	bulwark(k,outline,DECK,rail_h,trim if kind!="wreck" else Color("5a4a3a"),gap,shapes,kind)
	match kind:
		"narrowboat":
			# cabins fore and aft, an open hold amidships (cargo, a seat)
			for c in [[-L*.5+.9,-L*.18],[L*.16,L*.5-1.]]:
				cabin(k,shapes,Vector3((c[0]+c[1])*.5,DECK,0),Vector3(c[1]-c[0],1.45,B-.5),hull_col.lightened(.08),trim,"porthole")
			for i in range(3):k.box(Vector3(-L*.16+.9+i*.75,DECK+.25,0),Vector3(.6,.5,.7),WOOD.darkened(.05*i),true)
			k.box(Vector3(-L*.5+.35,DECK+.6,0),Vector3(.06,1.2,.06),DARK,true) # tiller post
			P.cyl(k,Vector3(-L*.5+.35,DECK+1.15,0),Vector3(-L*.5+1.1,DECK+1.0,0),.03,WOOD,5)
			for i in range(3):P.lathe(k,Vector3(L*.25+i*.6,DECK+1.45,(i%2-.5)*.6),Basis(),[[0.,0.],[.12,0.],[.15,.2],[0.,.2]],Color("b5634a"),8);PropCatalog.bush(k,Vector3(L*.25+i*.6,DECK+1.62,(i%2-.5)*.6),.16,hs+i)
		"houseboat":
			cabin(k,shapes,Vector3(-3.,DECK,0),Vector3(3.,2.2,B-.4),hull_col.lightened(.1),trim,"window")
			k.box(Vector3(-3.,DECK+2.3,0),Vector3(3.3,.12,B+.1),trim,true) # roof overhang
			k.box(Vector3(L*.18,DECK+.25,-.6),Vector3(.8,.5,.5),WOOD,true) # bench
			P.lathe(k,Vector3(L*.3,DECK,.6),Basis(),[[0.,0.],[.2,0.],[.24,.35],[0.,.35]],Color("b5634a"),8);PropCatalog.bush(k,Vector3(L*.3,DECK+.35,.6),.25,hs)
		"launch":
			k.box(Vector3(1.8,DECK+.35,0),Vector3(.5,.7,B-.6),WHITE,true) # console
			P.quad(k,Vector3(2.1,DECK+.7,-B*.38),Vector3(2.1,DECK+.7,B*.38),Vector3(1.9,DECK+1.15,B*.38),Vector3(1.9,DECK+1.15,-B*.38),Vector3(.9,.45,0).normalized(),Color("8fb8cc"))
			for z in [-.55,.55]:k.box(Vector3(-2.2,DECK+.25,z),Vector3(.8,.5,.6),trim,true) # seats
			shapes.append(box_shape(Vector3(1.8,DECK+.35,0),Vector3(.5,.7,B-.6)))
			k.box(Vector3(-L*.5+.2,DECK+.1,0),Vector3(.5,.8,.5),DARK,true) # outboard motor
		"fishing":
			cabin(k,shapes,Vector3(-2.7,DECK,0),Vector3(2.4,2.1,B-.8),WHITE,trim,"window")
			P.cyl(k,Vector3(-2.7,DECK+2.1,0),Vector3(-2.7,DECK+4.6,0),.06,DARK,6) # mast
			P.cyl(k,Vector3(-2.7,DECK+3.0,0),Vector3(1.6,DECK+2.4,0),.04,DARK,6) # boom
			k.xf=Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(2.3,DECK+.55,0))
			P.lathe(k,Vector3(0,-.6,0),Basis(),[[0.,0.],[.5,0.],[.5,.1],[.32,.12,Color("5a7a6a")],[.32,1.08],[.5,1.1,trim],[.5,1.2],[0.,1.2]],trim,12) # net drum
			k.xf=Transform3D()
			shapes.append(box_shape(Vector3(2.3,DECK+.55,0),Vector3(1.0,1.1,1.2)))
			for i in range(3):PropCatalog.crate(k,Vector3(-L*.1+(i%2)*.7,DECK+(i/2)*.4,-B*.28),Vector3(.6,.4,.5),Color("2f6fb8"))
		"tug":
			cabin(k,shapes,Vector3(2.4,DECK,0),Vector3(1.8,2.6,B-.9),WHITE,trim,"window")
			P.lathe(k,Vector3(-2.2,DECK,0),Basis(),[[0.,0.],[.4,0.],[.4,2.8,trim],[.42,2.9],[0.,2.9]],hull_col.darkened(.1),10) # funnel
			shapes.append([cyl_shape(.4,2.9),Transform3D(Basis(),Vector3(-2.2,DECK+1.45,0))])
			for i in range(5):
				for side in [-1.,1.]:
					k.xf=Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(-L*.35+i*1.4,DECK-.25,side*(B*.5+.12)))
					P.tyre(k);k.xf=Transform3D() # fender tyres
			P.lathe(k,Vector3(-3.3,DECK,0),Basis(),[[0.,0.],[.2,0.],[.2,.5],[.28,.55],[.28,.62],[0.,.62]],DARK,10) # towing bitt
		"lighter":
			for x in [-L*.32,L*.3]:
				var c=Vector3(x,DECK,0)
				k.box(c+Vector3(0,1.3,0),Vector3(2.4,2.6,B-1.),Color(["c9503a","2f6fb8","3f7f5f","e0a02f"][(absi(hs)+int(x))%4]),true) # container
				for i in range(8):k.box(c+Vector3(-1.1+i*.31,1.3,(B-1.)*.5+.01),Vector3(.12,2.5,.02),Color("2a3036"),true)
				shapes.append(box_shape(c+Vector3(0,1.3,0),Vector3(2.4,2.6,B-1.)))
			for i in range(4):PropCatalog.crate(k,Vector3(-1.2+i*.8,DECK,(i%2-.5)*1.2),Vector3(.7,.6,.7),WOOD)
			for i in range(4):shapes.append(box_shape(Vector3(-1.2+i*.8,DECK+.3,(i%2-.5)*1.2),Vector3(.7,.6,.7)))
		"patrol":
			cabin(k,shapes,Vector3(-2.6,DECK,0),Vector3(2.2,1.9,B-.7),Color("8a949c"),DARK,"slit")
			P.cyl(k,Vector3(-2.6,DECK+1.9,0),Vector3(-2.6,DECK+3.4,0),.05,DARK,6)
			k.box(Vector3(-2.6,DECK+3.1,0),Vector3(.1,.1,1.2),DARK,true) # radar
			# bow gun mount
			P.lathe(k,Vector3(L*.3,DECK,0),Basis(),[[0.,0.],[.35,0.],[.35,.5],[.25,.6],[0.,.6]],Color("6f7a82"),10)
			P.cyl(k,Vector3(L*.3,DECK+.65,0),Vector3(L*.3+1.1,DECK+.75,0),.05,DARK,6)
			shapes.append([cyl_shape(.35,.6),Transform3D(Basis(),Vector3(L*.3,DECK+.3,0))])
			k.box(Vector3(-2.6,.25,(B*.5+.01)*(1 if absi(hs)%2 else -1)),Vector3(1.4,.3,.02),WHITE,true) # hull number
		"workboat":
			cabin(k,shapes,Vector3(-2.2,DECK,0),Vector3(1.4,1.8,B-.6),WHITE,trim,"window")
			P.cyl(k,Vector3(1.9,DECK,0),Vector3(1.9,DECK+1.6,0),.06,DARK,6) # davit
			P.cyl(k,Vector3(1.9,DECK+1.6,0),Vector3(2.6,DECK+1.5,0),.05,DARK,6)
		"wreck":
			# broken wheelhouse, rust patches, holes in the deck (painted)
			cabin(k,shapes,Vector3(-2.9,DECK,0),Vector3(2.2,1.6,B-.8),Color("8a7a6a"),Color("5a4a3a"),"broken")
			for i in range(5):k.box(Vector3(-L*.35+i*1.4,DECK+.004,((i*37+absi(hs))%5-2)*.3),Vector3(.7,.01,.5),Color("3a2a22"),true)
			for i in range(4):k.box(Vector3(-L*.3+i*1.8,.4,(B*.5+.01)),Vector3(.8,.5,.02),Color("8a4a2a"),true)
			P.cyl(k,Vector3(-2.9,DECK+1.6,0),Vector3(-3.6,DECK+3.4,.3),.06,DARK,6) # bent mast
		"punt":
			P.cyl(k,Vector3(-1.,DECK+.05,.3),Vector3(1.9,DECK+.2,.4),.03,WOOD.lightened(.1),5) # pole
			k.box(Vector3(0,DECK+.15,0),Vector3(.5,.1,B-.2),WOOD,true) # seat
		"ferry":
			# a long passenger saloon with doors both sides, benches inside, a bridge on top
			deckhouse(k,shapes,Vector3(-1.,DECK,0),Vector3(11.,2.5,B-1.4),WHITE,trim,[-3.,2.])
			for i in range(4):
				for side in [-1.,1.]:k.box(Vector3(-5.+i*2.6,DECK+.25,side*(B*.5-1.25)),Vector3(1.6,.5,.5),trim.darkened(.25),true) # benches
			k.box(Vector3(2.5,DECK+2.5+.75,0),Vector3(2.6,1.5,B-2.4),WHITE,true)
			shapes.append(box_shape(Vector3(2.5,DECK+2.5+.75,0),Vector3(2.6,1.5,B-2.4)))
			k.box(Vector3(3.83,DECK+3.45,0),Vector3(.02,.5,B-2.8),GLASS,true)
		"freighter":
			# containers forward (cover), a walk-in bridge house aft with a funnel
			for i in range(3):
				for side in [-1.,1.]:
					var c=Vector3(1.5+i*2.8,DECK,side*1.55)
					k.box(c+Vector3(0,1.3,0),Vector3(2.6,2.6,2.4),Color(["c9503a","2f6fb8","3f7f5f","e0a02f"][(absi(hs)+i+int(side))%4]),true)
					shapes.append(box_shape(c+Vector3(0,1.3,0),Vector3(2.6,2.6,2.4)))
			deckhouse(k,shapes,Vector3(-7.5,DECK,0),Vector3(6.,2.6,B-1.2),WHITE,trim,[-1.])
			P.lathe(k,Vector3(-9.6,DECK+2.7,0),Basis(),[[0.,0.],[.55,0.],[.55,2.2,trim],[.6,2.3],[0.,2.3]],hull_col.darkened(.2),10) # funnel
		"trawler":
			deckhouse(k,shapes,Vector3(-3.,DECK,0),Vector3(5.,2.4,B-1.2),WHITE,trim,[0.])
			P.cyl(k,Vector3(2.5,DECK,0),Vector3(2.5,DECK+5.,0),.08,DARK,6) # mast
			P.cyl(k,Vector3(2.5,DECK+3.6,0),Vector3(6.,DECK+2.2,0),.05,DARK,6) # boom
			for i in range(3):PropCatalog.crate(k,Vector3(4.+(i%2)*.8,DECK,-B*.25+(i/2)*.7),Vector3(.7,.45,.6),Color("2f6fb8"))
			for i in range(3):shapes.append(box_shape(Vector3(4.+(i%2)*.8,DECK+.22,-B*.25+(i/2)*.7),Vector3(.7,.45,.6)))
		"barge":
			# a long open hold with cargo to hide behind, a small wheelhouse aft you can enter
			for i in range(4):
				k.box(Vector3(-2.+i*2.6,DECK+.6,(i%2-.5)*1.4),Vector3(1.8,1.2,1.4),WOOD.darkened(.05*i),true)
				shapes.append(box_shape(Vector3(-2.+i*2.6,DECK+.6,(i%2-.5)*1.4),Vector3(1.8,1.2,1.4)))
			deckhouse(k,shapes,Vector3(-6.4,DECK,0),Vector3(3.6,2.3,B-1.2),hull_col.lightened(.3),trim,[0.])
	return shapes
## 1.5.4: a deckhouse players walk into - four walls with a doorway in each long side at
## each `doors` offset (x), windows above the waist, a roof; collision for walls and roof only.
static func deckhouse(k:DistrictFacade.Kit,shapes:Array,base:Vector3,s:Vector3,col:Color,trim:Color,doors:Array):
	var t=.12;var door_w=1.3;var door_h=2.1
	for side in [-1.,1.]:
		var z=base.z+side*(s.z*.5-t*.5)
		# wall pieces between the doorways
		var cuts=[base.x-s.x*.5]
		for d in doors:cuts.append(base.x+float(d)-door_w*.5);cuts.append(base.x+float(d)+door_w*.5)
		cuts.append(base.x+s.x*.5)
		for i in range(0,cuts.size(),2):
			var x0=cuts[i];var x1=cuts[i+1]
			if x1-x0<.05:continue
			k.box(Vector3((x0+x1)*.5,base.y+s.y*.5,z),Vector3(x1-x0,s.y,t),col,true)
			shapes.append(box_shape(Vector3((x0+x1)*.5,base.y+s.y*.5,z),Vector3(x1-x0,s.y,t)))
			var n=maxi(1,int((x1-x0)/1.2))
			for w in range(n):
				var wx=x0+(x1-x0)*(w+.5)/n
				k.box(Vector3(wx,base.y+s.y*.66,z+side*(t*.5+.012)),Vector3((x1-x0)/n*.7,.6,.024),GLASS,true)
		for d in doors:
			var x=base.x+float(d)
			k.box(Vector3(x,base.y+door_h+(s.y-door_h)*.5,z),Vector3(door_w,s.y-door_h,t),col,true) # lintel
			shapes.append(box_shape(Vector3(x,base.y+door_h+(s.y-door_h)*.5,z),Vector3(door_w,s.y-door_h,t)))
	for end in [-1.,1.]:
		var x=base.x+end*(s.x*.5-t*.5)
		k.box(Vector3(x,base.y+s.y*.5,base.z),Vector3(t,s.y,s.z-2.*t),col,true)
		shapes.append(box_shape(Vector3(x,base.y+s.y*.5,base.z),Vector3(t,s.y,s.z-2.*t)))
		k.box(Vector3(x+end*(t*.5+.012),base.y+s.y*.66,base.z),Vector3(.024,.6,s.z*.7),GLASS,true)
	k.box(Vector3(base.x,base.y+s.y+.08,base.z),Vector3(s.x+.3,.16,s.z+.3),trim,true) # roof
	shapes.append(box_shape(Vector3(base.x,base.y+s.y+.08,base.z),Vector3(s.x+.3,.16,s.z+.3)))
static func box_shape(c:Vector3,s:Vector3) -> Array:
	var b=BoxShape3D.new();b.size=s;return [b,Transform3D(Basis(),c)]
static func cyl_shape(r:float,h:float) -> CylinderShape3D:
	var s=CylinderShape3D.new();s.radius=r;s.height=h;return s
## Plan outline (x, z) of the deck edge, convex, counter-clockwise.
static func plan(L:float,B:float,bow:float,blunt:bool) -> Array:
	var out=[]
	var n=12 # (1.5.0: the hull's own sections - with 8 the deck's edge cut inside the hull's rim and left slits)
	# starboard side stern -> bow
	for i in range(n+1):
		var x=-L*.5+L*i/n
		out.append(Vector2(x,-half_width(x,L,B,bow,blunt)))
	for i in range(n,-1,-1):
		var x=-L*.5+L*i/n
		out.append(Vector2(x,half_width(x,L,B,bow,blunt)))
	# drop duplicate points (pointed bow)
	var clean=[]
	for p in out:
		if clean.is_empty() or (clean[-1] as Vector2).distance_to(p)>.01:clean.append(p)
	return clean
static func half_width(x:float,L:float,B:float,bow:float,blunt:bool) -> float:
	var w=B*.5
	if x>L*.5-bow:
		var t=clampf((x-(L*.5-bow))/bow,0.,1.)
		w*= (1.-t*t*.55) if blunt else (1.-pow(t,1.7))
		if not blunt:w=maxf(w,.04)
	if x<-L*.5+.6:w*=.94
	return w
## Lofted hull: sections along X, each from the deck edge down to the keel.
static func hull(k:DistrictFacade.Kit,L:float,B:float,deck_h:float,draft:float,bow:float,col:Color,trim:Color,blunt:bool):
	var n=12
	var anti=Color("8a2f2f") if col!=Color("6a4a3a") else Color("4a3a32")
	var stripe=trim
	var rows=[[deck_h,1.,col],[.18,.99,stripe],[-.02,.97,anti],[-draft*.55,.82,anti],[-draft,.3,anti]]
	var prev=[]
	for i in range(n+1):
		var x=-L*.5+L*i/n
		var w=half_width(x,L,B,bow,blunt)
		var keel=1.-(clampf((x-(L*.5-bow))/bow,0.,1.)*.6 if not blunt else 0.)
		var sec=[]
		for r in rows:sec.append(Vector3(x,maxf(float(r[0])*(keel if float(r[0])<0. else 1.),-draft),w*float(r[1])))
		if not prev.is_empty():
			for side in [-1.,1.]:
				for j in range(rows.size()-1):
					var a=prev[j]*Vector3(1,1,side);var b=sec[j]*Vector3(1,1,side);var c=sec[j+1]*Vector3(1,1,side);var d=prev[j+1]*Vector3(1,1,side)
					var nrm=((b-a).cross(d-a)).normalized()
					if nrm.z*side<0.:nrm=-nrm
					if nrm.length()<.5:nrm=Vector3(0,0,side)
					P.quad(k,a,b,c,d,nrm,rows[j][2])
				# keel flat between the two sides
			var ka=prev[-1];var kb=sec[-1]
			P.quad(k,ka*Vector3(1,1,-1),kb*Vector3(1,1,-1),kb,ka,Vector3.DOWN,anti)
		prev=sec
	# transom (stern face)
	var x0=-L*.5;var w0=half_width(x0,L,B,bow,blunt)
	var tp=[]
	for r in rows:tp.append(Vector2(w0*float(r[1]),float(r[0])))
	for j in range(rows.size()-1):
		var a=Vector3(x0,tp[j].y,-tp[j].x);var b=Vector3(x0,tp[j].y,tp[j].x);var c=Vector3(x0,tp[j+1].y,tp[j+1].x);var d=Vector3(x0,tp[j+1].y,-tp[j+1].x)
		P.quad(k,a,b,c,d,Vector3.LEFT,rows[j][2])
	# (1.5.0, the user: a seam down a boat's bow): a pointed bow ends a few cm
	# wide - its stem face is closed too, not only a blunt bow's
	for j in range(rows.size()-1):
		var a:Vector3=prev[j]*Vector3(1,1,-1);var b:Vector3=prev[j];var c:Vector3=prev[j+1];var d:Vector3=prev[j+1]*Vector3(1,1,-1)
		P.quad(k,a,b,c,d,Vector3.RIGHT,rows[j][2])
static func deck(k:DistrictFacade.Kit,outline:Array,y:float,col:Color):
	var c=Vector3(0,y+.004,0)
	for i in range(outline.size()):
		var a:Vector2=outline[i];var b:Vector2=outline[(i+1)%outline.size()]
		P.tri(k,c,Vector3(a.x,y+.004,a.y),Vector3(b.x,y+.004,b.y),Vector3.UP,Vector3.UP,Vector3.UP,col.darkened(.04*(i%2)))
	# planking lines
	var minx=INF;var maxx=-INF
	for p in outline:minx=minf(minx,p.x);maxx=maxf(maxx,p.x)
## Bulwark: a low rail along the deck edge, open amidships on the gap side.
static func bulwark(k:DistrictFacade.Kit,outline:Array,y:float,h:float,col:Color,gap:int,shapes:Array,kind:String):
	for i in range(outline.size()):
		var a:Vector2=outline[i];var b:Vector2=outline[(i+1)%outline.size()]
		var mid=(a+b)*.5
		if a.distance_to(b)<.05:continue
		if gap!=0 and signf(mid.y)==float(gap) and absf(mid.x)<1.4:continue # the boarding opening
		var d=b-a;var length=d.length();var yaw=atan2(-d.y,d.x)
		var c=Vector3(mid.x,y+h*.5,mid.y)
		var keep=k.xf
		k.xf=keep*Transform3D(Basis(Vector3.UP,yaw),c)
		if kind in ["patrol","launch","houseboat"]:
			P.cyl(k,Vector3(-length*.5,h*.5,0),Vector3(length*.5,h*.5,0),.025,Color("c8ccd0"),5) # pipe rail
			k.box(Vector3(0,-h*.25,0),Vector3(length,h*.5,.06),col,true)
		else:
			k.box(Vector3(0,0,0),Vector3(length,h,.08),col,true)
			k.box(Vector3(0,h*.5+.02,0),Vector3(length+.04,.05,.14),col.lightened(.15),true) # capping rail
		k.xf=keep
		var s=BoxShape3D.new();s.size=Vector3(length,h,.1)
		shapes.append([s,Transform3D(Basis(Vector3.UP,yaw),c)])
## Deckhouse with windows, roof and a door, solid for collision.
static func cabin(k:DistrictFacade.Kit,shapes:Array,base:Vector3,s:Vector3,col:Color,trim:Color,windows:String):
	P.cbox(k,base+Vector3(0,s.y*.5,0),s,col,.06)
	k.box(base+Vector3(0,s.y+.06,0),Vector3(s.x+.2,.12,s.z+.2),trim,true) # roof
	for side in [-1.,1.]:
		var z=side*(s.z*.5+.025)
		var n=maxi(1,int(s.x/1.1))
		for i in range(n):
			var x=base.x-s.x*.5+s.x*(i+.5)/n
			match windows:
				"porthole":k.xf=Transform3D(Basis(Vector3.UP,0. if side>0 else PI),Vector3(x,base.y+s.y*.6,z));k.disc(Vector3.ZERO,.16,GLASS,10);k.xf=Transform3D()
				"slit":k.box(Vector3(x,base.y+s.y*.72,z),Vector3(s.x/n*.7,.18,.01),GLASS,true)
				"broken":k.box(Vector3(x,base.y+s.y*.65,z),Vector3(s.x/n*.6,.45,.01),DARK if i%2 else GLASS,true)
				_:k.box(Vector3(x,base.y+s.y*.65,z),Vector3(s.x/n*.7,.55,.01),GLASS,true)
	# front windows (toward the bow) and a door aft
	k.box(base+Vector3(s.x*.5+.006,s.y*.68,0),Vector3(.01,.5,s.z*.8),GLASS,true)
	k.box(base+Vector3(-s.x*.5-.006,s.y*.42,0),Vector3(.01,s.y*.8,.7),trim.darkened(.2),true)
	shapes.append(box_shape(base+Vector3(0,s.y*.5,0),s))
