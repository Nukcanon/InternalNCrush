class_name PropModels
extends RefCounted
## 1.4.5 remodel (the user): the old generated map pieces - parked vehicles,
## steel drums and wooden casks, the big water tank, cable drums, loose tyres -
## rebuilt with real shapes: vehicles from side silhouettes (body, cabin,
## glass, wheel arches) at real proportions, round things as smooth lathed
## profiles. Costly parts are kept cheap (12-sided low wheels, no tread blocks).
## Everything is one vertex-coloured mesh per prop (DistrictFacade.Kit.detail),
## drawn with the world "detail" material like the other procedural props.
const RUBBER=Color("2a2c30")
const RIM=Color("aeb6bd")
const GLASS=Color("2f3d4a")
const GLASS_HI=Color("587086")
const TRIM=Color("3a3f45")
const LAMP=Color("fff1c4")
const TAIL=Color("c8302b")
const AMBER=Color("efa233")
const PLATE=Color("eef0e8")
const BODY=[Color("d8d6cf"),Color("b8403a"),Color("38689e"),Color("e2b13a"),Color("4d7a52"),Color("6a7078"),Color("2f3b52")]
# Old transport set names -> the remodelled vehicle types.
const VEHICLES={"vehicle_compact":"compact","vehicle_hatch":"hatch","vehicle_sedan":"sedan","vehicle_taxi":"taxi","vehicle_estate":"hatch",
	"vehicle_utility":"suv","vehicle_van":"van","vehicle_minibus":"van","vehicle_ambulance":"van","vehicle_pickup":"pickup",
	"vehicle_delivery":"box","vehicle_box":"box","vehicle_reefer":"box","vehicle_fire":"box","vehicle_flatbed":"flatbed",
	"vehicle_dump":"dump","vehicle_refuse":"dump","vehicle_tow":"tow","vehicle_crane":"tow","vehicle_tanker":"flatbed"}
const ROUND=["drums","cask_pair","cable_drum","watertank_floor"]
static func has(kind:String) -> bool:return VEHICLES.has(kind) or kind in ROUND
static func build(k:DistrictFacade.Kit,kind:String,hs:int) -> AABB:
	if VEHICLES.has(kind):return vehicle(k,VEHICLES[kind],hs)
	match kind:
		"drums":
			for i in range(3):drum(k,Vector3([-.45,.45,0.][i],0,[-.2,-.2,.45][i]),.35,.93,[Color("c9503a"),Color("3f7fbf"),Color("e0b83a"),Color("4f8a5a")][(hs+i)%4],(hs+i)%3==0)
			return AABB(Vector3(-.85,0,-.6),Vector3(1.7,.95,1.4))
		"cask_pair":
			for i in range(3):cask(k,Vector3([-.45,.45,0.][i],0,[-.2,-.2,.45][i]),.37,.95,Color("9a6438").darkened(.06*((hs+i)%3)))
			return AABB(Vector3(-.85,0,-.6),Vector3(1.7,.95,1.4))
		"cable_drum":return spool(k,hs)
		"watertank_floor":return water_tank(k,hs)
	return AABB()
# --- primitives --------------------------------------------------------------
## One triangle with per-vertex normals (outward); wound for Godot's front face
## whatever order it is given in.
static func tri(k:DistrictFacade.Kit,a:Vector3,b:Vector3,c:Vector3,na:Vector3,nb:Vector3,nc:Vector3,col:Color):
	if (b-a).cross(c-a).dot(na+nb+nc)>0.:
		var t=b;b=c;c=t;var tn=nb;nb=nc;nc=tn
	var st:SurfaceTool=k.detail
	st.set_color(col);st.set_normal((k.xf.basis*na).normalized());st.add_vertex(k.xf*a)
	st.set_color(col);st.set_normal((k.xf.basis*nb).normalized());st.add_vertex(k.xf*b)
	st.set_color(col);st.set_normal((k.xf.basis*nc).normalized());st.add_vertex(k.xf*c)
	k.tris+=1
static func quad(k:DistrictFacade.Kit,a:Vector3,b:Vector3,c:Vector3,d:Vector3,n:Vector3,col:Color):
	tri(k,a,b,c,n,n,n,col);tri(k,a,c,d,n,n,n,col)
## Surface of revolution round frame.y through `at`: profile [[radius, height,
## (colour of the segment from here)],...] counter-clockwise in (r, h) - out
## along the bottom, up the side, in across the top - so normals face out.
## Smooth round the axis, crisp at the profile corners. `stripes` alternates
## the shade per side (staves, tread).
static func lathe(k:DistrictFacade.Kit,at:Vector3,frame:Basis,profile:Array,col:Color,sides:int=14,closed:bool=false,stripes:float=0.):
	var count=profile.size() if closed else profile.size()-1
	var segment_col=col
	for j in range(count):
		var p0:Array=profile[j];var p1:Array=profile[(j+1)%profile.size()]
		if p0.size()>2:segment_col=p0[2]
		var dr=float(p1[0])-float(p0[0]);var dh=float(p1[1])-float(p0[1])
		var nr=dh;var na=-dr;var length=sqrt(nr*nr+na*na)
		if length<.00001:continue
		nr/=length;na/=length
		for i in range(sides):
			var a0=TAU*i/sides;var a1=TAU*(i+1)/sides
			var d0=frame.x*cos(a0)+frame.z*sin(a0);var d1=frame.x*cos(a1)+frame.z*sin(a1)
			var v00=at+d0*float(p0[0])+frame.y*float(p0[1]);var v01=at+d1*float(p0[0])+frame.y*float(p0[1])
			var v10=at+d0*float(p1[0])+frame.y*float(p1[1]);var v11=at+d1*float(p1[0])+frame.y*float(p1[1])
			var n0=d0*nr+frame.y*na;var n1=d1*nr+frame.y*na
			var c=segment_col.darkened(stripes) if stripes>0. and i%2==1 else segment_col
			if float(p0[0])>.00001:tri(k,v00,v01,v11,n0,n1,n1,c)
			if float(p1[0])>.00001:tri(k,v00,v11,v10,n0,n1,n0,c)
## A frame whose y is `axis` (for lathe).
static func axis_frame(axis:Vector3) -> Basis:
	var y=axis.normalized();var x=Vector3.UP.cross(y)
	if x.length()<.1:x=Vector3.RIGHT
	x=x.normalized();var z=x.cross(y).normalized()
	return Basis(x,y,z)
static func cyl(k:DistrictFacade.Kit,a:Vector3,b:Vector3,r:float,col:Color,sides:int=10):
	var length=a.distance_to(b)
	lathe(k,a,axis_frame(b-a),[[0.,0.],[r,0.],[r,length],[0.,length]],col,sides)
## Side silhouette (x, y) extruded across z0..z1 (z1 > z0).
static func extrude(k:DistrictFacade.Kit,poly:PackedVector2Array,z0:float,z1:float,col:Color,side_col=null):
	var ids=Geometry2D.triangulate_polygon(poly)
	if ids.is_empty():return
	for i in range(0,ids.size(),3):
		var p=[poly[ids[i]],poly[ids[i+1]],poly[ids[i+2]]]
		tri(k,Vector3(p[0].x,p[0].y,z1),Vector3(p[1].x,p[1].y,z1),Vector3(p[2].x,p[2].y,z1),Vector3.BACK,Vector3.BACK,Vector3.BACK,col)
		tri(k,Vector3(p[0].x,p[0].y,z0),Vector3(p[1].x,p[1].y,z0),Vector3(p[2].x,p[2].y,z0),Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD,col)
	var area=0.
	for i in range(poly.size()):area+=poly[i].cross(poly[(i+1)%poly.size()])
	var rim:Color=side_col if side_col!=null else col
	for i in range(poly.size()):
		var p:Vector2=poly[i];var q:Vector2=poly[(i+1)%poly.size()];var d=q-p
		if d.length()<.00001:continue
		var n2=Vector2(d.y,-d.x).normalized()*(1. if area>0. else -1.)
		var n=Vector3(n2.x,n2.y,0.)
		# tops lighter, undersides darker (cel shading reads the facets)
		var shade=rim.lightened(.05) if n2.y>.5 else rim.darkened(.1) if n2.y<-.5 else rim
		quad(k,Vector3(p.x,p.y,z0),Vector3(q.x,q.y,z0),Vector3(q.x,q.y,z1),Vector3(p.x,p.y,z1),n,shade)
static func pts(list:Array) -> PackedVector2Array:
	var out=PackedVector2Array()
	for p in list:out.append(Vector2(p[0],p[1]))
	return out
## Box with chamfered edges (three crossing boxes).
static func cbox(k:DistrictFacade.Kit,c:Vector3,s:Vector3,col:Color,b:float=.03):
	b=minf(b,minf(s.x,minf(s.y,s.z))*.3)
	k.box(c,Vector3(s.x,s.y-2.*b,s.z-2.*b),col,true);k.box(c,Vector3(s.x-2.*b,s.y,s.z-2.*b),col,true);k.box(c,Vector3(s.x-2.*b,s.y-2.*b,s.z),col,true)
## Half disc (an arch) in the xy plane at z, both faces, thickness t outward.
static func arch_slab(k:DistrictFacade.Kit,cx:float,cy:float,r:float,z:float,t:float,col:Color):
	var poly=[]
	for i in range(9):var a=PI*i/8.;poly.append([cx+cos(a)*r,cy+sin(a)*r])
	extrude(k,pts(poly),z-(t if z<0 else 0.),z+(0. if z<0 else t),col)
# --- wheels ------------------------------------------------------------------
## A low wheel: 12-sided tyre with rounded shoulders, a rim and hub, its outer
## face toward side (+1: +z).
static func wheel(k:DistrictFacade.Kit,at:Vector3,r:float,w:float,side:float,rim:Color=RIM):
	var frame=Basis(Vector3.RIGHT,Vector3(0,0,side),Vector3.RIGHT.cross(Vector3(0,0,side)))
	var h=w*.5
	lathe(k,at,frame,[[r*.6,-h],[r*.9,-h],[r,-h*.6],[r,h*.6],[r*.9,h],[r*.62,h],[r*.6,h*.85]],RUBBER,12)
	lathe(k,at,frame,[[r*.6,h*.85,rim],[r*.52,h*.7],[r*.2,h*.7,rim.darkened(.25)],[r*.16,h*.95],[0.,h*.95]],rim,12)
# --- vehicles ----------------------------------------------------------------
## Builds a vehicle along local X (front +X), on the ground, centred; returns
## its footprint (collision keeps the old rule: the box up to 1.6 m).
static func vehicle(k:DistrictFacade.Kit,type:String,hs:int) -> AABB:
	var body:Color=BODY[hs%BODY.size()]
	if type=="taxi":body=Color("e8b630")
	var L=4.4;var W=1.78;var wr=.33;var ww=.22;var axles=[1.35,-1.35];var dual=false
	match type:
		"compact":L=3.2;W=1.68;wr=.31;axles=[1.0,-.98]
		"hatch":L=3.7;W=1.74;axles=[1.17,-1.13]
		"sedan","taxi":L=4.6;W=1.8;axles=[1.42,-1.36]
		"suv":L=4.1;W=1.86;wr=.36;ww=.25;axles=[1.28,-1.22]
		"van":L=5.05;W=1.98;wr=.36;ww=.24;axles=[1.62,-1.6]
		"pickup":L=4.95;W=1.92;wr=.38;ww=.26;axles=[1.62,-1.45]
		"box","flatbed":L=5.7;W=2.25;wr=.46;ww=.27;axles=[1.8,-1.6];dual=true
		"dump":L=6.2;W=2.3;wr=.48;ww=.28;axles=[2.05,-1.45,-2.5];dual=true
		"tow":L=6.3;W=2.3;wr=.48;ww=.28;axles=[2.05,-1.55,-2.6];dual=true
	var f=L*.5;var hw=W*.5
	match type:
		"compact","hatch","sedan","taxi","suv":car(k,type,L,W,body,hs)
		"van":van(k,L,W,body)
		"pickup":pickup(k,L,W,body)
		_:truck(k,type,L,W,body,hs)
	# wheels (dual rear wheels on trucks), arches drawn by the body builders
	for x in axles:
		for side in [-1.,1.]:
			var rear=x<0. and dual
			wheel(k,Vector3(x,wr,side*(hw-ww*.5-(.0 if not rear else .0))),wr,ww,side)
			if rear:wheel(k,Vector3(x,wr,side*(hw-ww*1.55)),wr,ww,side)
	var top={"compact":1.5,"hatch":1.48,"sedan":1.45,"taxi":1.62,"suv":1.8,"van":2.15,"pickup":1.86,"box":3.,"flatbed":2.45,"dump":2.75,"tow":2.95}[type]
	return AABB(Vector3(-f,0,-hw-.12),Vector3(L,top,W+.24))
static func lamps(k:DistrictFacade.Kit,f:float,y:float,hw:float,rear:float,ry:float,w:float=.26):
	for side in [-1.,1.]:
		k.box(Vector3(f-.015,y,side*(hw-.2)),Vector3(.05,.12,w),LAMP,true)
		k.box(Vector3(f-.012,y-.01,side*(hw-.05)),Vector3(.05,.08,.07),AMBER,true)
		k.box(Vector3(rear+.015,ry,side*(hw-.14)),Vector3(.05,.16,.2),TAIL,true)
static func mirrors(k:DistrictFacade.Kit,x:float,y:float,hw:float,col:Color,big:bool=false):
	for side in [-1.,1.]:
		k.box(Vector3(x,y,side*(hw+.06)),Vector3(.06,.03,.14),TRIM,true)
		cbox(k,Vector3(x-.02,y+(.1 if big else .04),side*(hw+.15)),Vector3(.07,.26 if big else .11,.13 if big else .17),col if not big else TRIM,.02)
static func side_glass(k:DistrictFacade.Kit,poly:Array,hw:float):
	for side in [-1.,1.]:
		var z=side*hw
		extrude(k,pts(poly),z-(.012 if side<0 else 0.),z+(0. if side<0 else .012),GLASS)
## Passenger cars: lower body and cabin from side silhouettes.
static func car(k:DistrictFacade.Kit,type:String,L:float,W:float,body:Color,hs:int):
	var f=L*.5;var r=-L*.5;var hw=W*.5
	var belt=.9 if type!="suv" else 1.05;var roof={"compact":1.5,"hatch":1.48,"sedan":1.45,"taxi":1.45,"suv":1.8}[type]
	var cowl=f-(1.05 if type in ["sedan","taxi"] else .95 if type=="suv" else .8)
	var hatchback=type in ["compact","hatch","suv"]
	var tail=r+(.95 if not hatchback else .12)
	# lower body: bumper, hood, beltline, trunk / hatch, sill
	var lower=[[f,.3],[f+.02,.55],[f-.06,.72],[f-.35,belt-.06],[cowl,belt],[r+.12,belt+.02],[r,belt-.12],[r-.02,.55],[r+.05,.3]]
	extrude(k,pts(lower),-hw,hw,body)
	# cabin (greenhouse) narrower than the body
	var cab_w=hw-.1;var a_top=cowl-(.78 if type!="suv" else .62);var rear_top=tail+(.35 if not hatchback else .22)
	var cabin=[[cowl,belt],[a_top,roof],[rear_top,roof],[tail,belt+(.02 if hatchback else .0)]]
	extrude(k,pts(cabin),-cab_w,cab_w,body)
	# glass: windscreen and rear screen on the slopes, side windows
	var wn=Vector3(roof-belt,cowl-a_top,0).normalized()
	quad(k,Vector3(cowl-.05,belt+.05,-cab_w+.06),Vector3(cowl-.05,belt+.05,cab_w-.06),Vector3(a_top+.04,roof-.04,cab_w-.08),Vector3(a_top+.04,roof-.04,-cab_w+.08),wn,GLASS)
	var lift=wn*.006
	quad(k,Vector3(cowl-.06,belt+.08,-cab_w+.1)+lift,Vector3(cowl-.06,belt+.08,-cab_w+.32)+lift,Vector3(a_top+.06,roof-.06,-cab_w+.26)+lift,Vector3(a_top+.06,roof-.06,-cab_w+.1)+lift,wn,GLASS_HI)
	var rn=Vector3(-(roof-belt),rear_top-tail,0).normalized()
	quad(k,Vector3(tail+.05,belt+.06,-cab_w+.06),Vector3(tail+.05,belt+.06,cab_w-.06),Vector3(rear_top-.04,roof-.05,cab_w-.08),Vector3(rear_top-.04,roof-.05,-cab_w+.08),rn,GLASS)
	var mid=(a_top+rear_top)*.5
	side_glass(k,[[cowl-.12,belt+.05],[a_top+.03,roof-.06],[mid+.05,roof-.06],[mid+.05,belt+.05]],cab_w)
	side_glass(k,[[mid-.05,belt+.05],[mid-.05,roof-.06],[rear_top+.04,roof-.06],[tail+.12,belt+.05]],cab_w)
	# pillars between the windows
	for side in [-1.,1.]:k.box(Vector3(mid,(belt+roof)*.5,side*(cab_w+.006)),Vector3(.08,roof-belt-.02,.014),TRIM,true)
	# wheel arches, sills, bumpers, grille, lamps, mirrors, handles, plates
	for x in [L*.31,-L*.3]:
		for side in [-1.,1.]:arch_slab(k,x,.3,.44,side*hw,.012,TRIM)
	for side in [-1.,1.]:k.box(Vector3(0,.3,side*(hw+.004)),Vector3(L-1.9,.1,.02),TRIM,true)
	cbox(k,Vector3(f-.02,.38,0),Vector3(.16,.18,W+.02),TRIM,.04);cbox(k,Vector3(r+.02,.38,0),Vector3(.16,.18,W+.02),TRIM,.04)
	k.box(Vector3(f+.012,.6,0),Vector3(.03,.14,W*.45),TRIM.darkened(.3),true)
	lamps(k,f,.66,hw,r,.74)
	mirrors(k,cowl-.08,belt+.06,cab_w,body)
	for side in [-1.,1.]:
		for x in [mid+.3,mid-.45]:k.box(Vector3(x,belt-.06,side*(hw+.008)),Vector3(.13,.03,.02),TRIM,true)
		k.box(Vector3(mid-.02,(belt+.3)*.5,side*(hw+.004)),Vector3(.012,belt-.36,.01),body.darkened(.25),true)
	k.box(Vector3(f+.03,.42,0),Vector3(.012,.1,.34),PLATE,true);k.box(Vector3(r-.03,.62,0),Vector3(.012,.1,.34),PLATE,true)
	if type=="taxi":
		cbox(k,Vector3((a_top+rear_top)*.5,roof+.08,0),Vector3(.3,.14,.6),Color("f6f2e4"),.03)
	if type=="suv":
		for side in [-1.,1.]:k.box(Vector3((a_top+rear_top)*.5,roof+.04,side*(cab_w-.12)),Vector3(rear_top-a_top-.3,.04,.05),TRIM,true)
		cbox(k,Vector3(r-.06,.72,0),Vector3(.1,.5,.5),RUBBER,.04)
## Van: one tall body with a short sloped nose.
static func van(k:DistrictFacade.Kit,L:float,W:float,body:Color):
	var f=L*.5;var r=-L*.5;var hw=W*.5
	var nose=f-.75;var roof=2.15
	extrude(k,pts([[f,.32],[f+.02,.62],[f-.08,.92],[nose,1.1],[nose-.62,roof-.06],[nose-.75,roof],[r+.06,roof],[r,roof-.06],[r,.32]]),-hw,hw,body)
	var wn=Vector3(roof-1.1,.62,0).normalized()
	quad(k,Vector3(nose-.02,1.15,-hw+.1),Vector3(nose-.02,1.15,hw-.1),Vector3(nose-.56,roof-.12,hw-.12),Vector3(nose-.56,roof-.12,-hw+.12),wn,GLASS)
	var lift=wn*.006
	quad(k,Vector3(nose-.04,1.2,-hw+.14)+lift,Vector3(nose-.04,1.2,-hw+.4)+lift,Vector3(nose-.5,roof-.16,-hw+.32)+lift,Vector3(nose-.5,roof-.16,-hw+.14)+lift,wn,GLASS_HI)
	side_glass(k,[[nose-.1,1.2],[nose-.6,roof-.15],[nose-1.25,roof-.15],[nose-1.25,1.2]],hw)
	side_glass(k,[[nose-1.4,1.25],[nose-1.4,roof-.18],[r+.35,roof-.18],[r+.35,1.25]],hw)
	k.box(Vector3(r-.006,1.55,0),Vector3(.012,.5,W-.5),GLASS,true)
	for side in [-1.,1.]:
		k.box(Vector3(nose-1.32,1.2,side*(hw+.005)),Vector3(.012,1.7,.01),body.darkened(.3),true) # sliding door seam
		k.box(Vector3(nose-2.6,1.55,side*(hw+.005)),Vector3(.9,.03,.012),TRIM,true) # door rail
		k.box(Vector3(nose-1.15,1.05,side*(hw+.008)),Vector3(.14,.03,.02),TRIM,true)
		for x in [L*.32,-L*.32]:arch_slab(k,x,.32,.47,side*hw,.012,TRIM)
		k.box(Vector3(0,.34,side*(hw+.004)),Vector3(L-2.,.12,.02),TRIM,true)
	k.box(Vector3(r-.006,1.1,0),Vector3(.012,1.7,.012),body.darkened(.3),true) # rear doors
	cbox(k,Vector3(f-.02,.42,0),Vector3(.18,.2,W+.02),TRIM,.04);cbox(k,Vector3(r+.02,.42,0),Vector3(.18,.2,W+.02),TRIM,.04)
	k.box(Vector3(f+.012,.72,0),Vector3(.03,.18,W*.5),TRIM.darkened(.3),true)
	lamps(k,f-.02,.8,hw,r,1.05,.3)
	mirrors(k,nose-.12,1.25,hw,body,true)
	k.box(Vector3(f+.03,.45,0),Vector3(.012,.1,.34),PLATE,true)
## Pickup: hood, cab, open bed with tailgate.
static func pickup(k:DistrictFacade.Kit,L:float,W:float,body:Color):
	var f=L*.5;var r=-L*.5;var hw=W*.5
	var cowl=f-1.45;var cab_back=cowl-1.55;var belt=1.12;var roof=1.86
	extrude(k,pts([[f,.4],[f+.02,.72],[f-.08,1.0],[cowl,belt],[cab_back,belt],[cab_back,.4]]),-hw,hw,body)
	var cw=hw-.08;var a_top=cowl-.6
	extrude(k,pts([[cowl,belt],[a_top,roof],[cab_back+.05,roof],[cab_back,belt]]),-cw,cw,body)
	var wn=Vector3(roof-belt,.6,0).normalized()
	quad(k,Vector3(cowl-.04,belt+.05,-cw+.06),Vector3(cowl-.04,belt+.05,cw-.06),Vector3(a_top+.04,roof-.04,cw-.08),Vector3(a_top+.04,roof-.04,-cw+.08),wn,GLASS)
	side_glass(k,[[cowl-.1,belt+.05],[a_top+.03,roof-.06],[cab_back+.15,roof-.06],[cab_back+.15,belt+.05]],cw)
	k.box(Vector3(cab_back-.006,belt+.38,0),Vector3(.012,.4,W-.6),GLASS,true)
	# bed: floor, side walls, front wall, tailgate
	var bed_len=cab_back-r-.05
	k.box(Vector3(r+bed_len*.5,.62,0),Vector3(bed_len,.08,W-.1),TRIM,true)
	for side in [-1.,1.]:cbox(k,Vector3(r+bed_len*.5,.84,side*(hw-.04)),Vector3(bed_len,.56,.08),body,.02)
	cbox(k,Vector3(cab_back-.08,.84,0),Vector3(.08,.56,W-.08),body,.02);cbox(k,Vector3(r+.04,.84,0),Vector3(.08,.56,W-.08),body,.02)
	k.box(Vector3(r-.006,.95,0),Vector3(.012,.08,.5),TRIM,true)
	for side in [-1.,1.]:
		for x in [L*.33,-L*.29]:arch_slab(k,x,.4,.5,side*hw,.015,TRIM)
		k.box(Vector3(cab_back+.6,belt-.08,side*(hw+.008)),Vector3(.14,.03,.02),TRIM,true)
		k.box(Vector3(cab_back+.05,(belt+.4)*.5+.05,side*(hw+.004)),Vector3(.012,.62,.01),body.darkened(.3),true)
	cbox(k,Vector3(f-.02,.5,0),Vector3(.18,.22,W+.04),RIM.darkened(.2),.04);cbox(k,Vector3(r+.02,.5,0),Vector3(.18,.2,W+.04),RIM.darkened(.2),.04)
	k.box(Vector3(f+.012,.8,0),Vector3(.03,.2,W*.55),TRIM.darkened(.3),true)
	lamps(k,f-.02,.86,hw,r,.95,.3)
	mirrors(k,cowl-.1,belt+.08,cw,body)
	k.box(Vector3(f+.03,.5,0),Vector3(.012,.1,.34),PLATE,true)
## Trucks: a short-nosed cab on a ladder frame and the load behind it.
static func truck(k:DistrictFacade.Kit,type:String,L:float,W:float,body:Color,hs:int):
	var f=L*.5;var r=-L*.5;var hw=W*.5
	var cab_back=f-2.05;var roof=2.6;var nose=f-.62
	var cab=body if type!="dump" else Color("e2a62f")
	# frame rails and fuel tank
	for side in [-1.,1.]:k.box(Vector3((cab_back+r)*.5+.4,.72,side*.42),Vector3(cab_back-r+.4,.22,.12),TRIM,true)
	cbox(k,Vector3(cab_back-.55,.78,hw-.28),Vector3(.9,.42,.4),RIM.darkened(.1),.08)
	# cab
	extrude(k,pts([[f,.55],[f+.02,1.0],[f-.06,1.3],[nose,1.42],[nose-.48,roof-.08],[nose-.58,roof],[cab_back,roof],[cab_back,.55]]),-hw+.02,hw-.02,cab)
	var wn=Vector3(roof-1.42,.48,0).normalized()
	quad(k,Vector3(nose-.02,1.5,-hw+.14),Vector3(nose-.02,1.5,hw-.14),Vector3(nose-.42,roof-.14,hw-.16),Vector3(nose-.42,roof-.14,-hw+.16),wn,GLASS)
	var lift=wn*.006
	quad(k,Vector3(nose-.04,1.56,-hw+.18)+lift,Vector3(nose-.04,1.56,-hw+.46)+lift,Vector3(nose-.36,roof-.18,-hw+.38)+lift,Vector3(nose-.36,roof-.18,-hw+.18)+lift,wn,GLASS_HI)
	side_glass(k,[[nose-.1,1.55],[nose-.46,roof-.16],[cab_back+.35,roof-.16],[cab_back+.35,1.55]],hw-.02)
	for side in [-1.,1.]:
		k.box(Vector3(cab_back+.25,1.5,side*(hw-.01)),Vector3(.012,1.6,.012),cab.darkened(.3),true)
		k.box(Vector3(cab_back+.55,1.35,side*(hw)),Vector3(.15,.03,.02),TRIM,true)
		# steps
		cbox(k,Vector3(nose-.45,.55,side*(hw-.08)),Vector3(.5,.06,.22),RIM.darkened(.2),.015)
		arch_slab(k,f-1.05,.5,.62,side*(hw-.02),.015,TRIM)
	cbox(k,Vector3(f-.02,.55,0),Vector3(.2,.26,W+.04),RIM.darkened(.25),.05)
	cbox(k,Vector3(f+.006,1.05,0),Vector3(.04,.38,W*.62),TRIM.darkened(.3),.01)
	for i in range(4):k.box(Vector3(f+.03,.92+i*.08,0),Vector3(.012,.025,W*.58),TRIM,true)
	lamps(k,f,1.0,hw,r+.05,.75,.32)
	mirrors(k,nose-.35,1.75,hw-.02,cab,true)
	for i in range(3):k.box(Vector3(cab_back+.6,roof+.03,(i-1)*.35),Vector3(.06,.05,.12),AMBER,true)
	k.box(Vector3(f+.03,.55,0),Vector3(.012,.12,.4),PLATE,true)
	# load
	var load_len=cab_back-r-.12
	var lx=r+load_len*.5
	match type:
		"box":
			var box_col=Color(["f0eee8","d8dde2","e8d6b8"][hs%3])
			cbox(k,Vector3(lx,1.92,0),Vector3(load_len,2.15,W+.06),box_col,.05)
			for side in [-1.,1.]:
				k.box(Vector3(lx,1.15,side*(hw+.035)),Vector3(load_len-.1,.18,.012),body,true) # livery stripe
				for x in [r+.08,cab_back-.2]:k.box(Vector3(x,1.92,side*(hw+.035)),Vector3(.08,2.1,.012),RIM.darkened(.2),true)
			for i in range(7):k.box(Vector3(r-.03,1.1+i*.28,0),Vector3(.012,.02,W-.2),RIM.darkened(.15),true) # roll-up door slats
			k.box(Vector3(lx,.84,0),Vector3(load_len,.16,W-.1),TRIM,true)
		"flatbed":
			k.box(Vector3(lx,1.0,0),Vector3(load_len,.12,W),Color("7a5a3c"),true)
			for side in [-1.,1.]:k.box(Vector3(lx,1.12,side*(hw-.03)),Vector3(load_len,.14,.06),RIM.darkened(.2),true)
			k.box(Vector3(cab_back-.15,1.6,0),Vector3(.08,1.,W-.1),RIM.darkened(.2),true) # headboard
			for i in range(2):
				var cx=r+.85+i*1.6
				cbox(k,Vector3(cx,1.52,0),Vector3(1.2,.9,1.3),Color("a77a4c").darkened(.08*i),.04)
				for s in [-.3,.3]:k.box(Vector3(cx+s,1.52,0),Vector3(.05,.94,1.34),Color("e0a83a"),true) # straps
		"dump":
			var bin_col=Color("c26a2e") if hs%2==0 else Color("8a8f95")
			var x0=r+.05;var x1=cab_back-.1
			k.box(Vector3((x0+x1)*.5,1.08,0),Vector3(x1-x0,.12,W-.1),bin_col.darkened(.2),true)
			for side in [-1.,1.]:
				var z=side*(hw-.04)
				extrude(k,pts([[x0,1.05],[x1,1.05],[x1+.05,2.35],[x0-.12,2.35]]),z-.04,z+.04,bin_col)
				for i in range(4):k.box(Vector3(x0+.3+i*(x1-x0-.6)/3.,1.7,side*(hw+.01)),Vector3(.08,1.25,.03),bin_col.darkened(.15),true)
			cbox(k,Vector3(x1,1.75,0),Vector3(.1,1.4,W-.08),bin_col,.03)
			cbox(k,Vector3(x0,1.6,0),Vector3(.1,1.1,W-.08),bin_col.darkened(.08),.03)
			# canopy over the cab
			k.box(Vector3(x1+.45,2.4,0),Vector3(.9,.06,W-.1),bin_col,true)
		"tow":
			k.box(Vector3(lx,1.0,0),Vector3(load_len,.14,W),RIM.darkened(.3),true)
			for side in [-1.,1.]:k.box(Vector3(lx,1.13,side*(hw-.05)),Vector3(load_len,.12,.08),Color("e0a83a"),true)
			# boom on a turret, cable and hook
			var base=Vector3(r+1.75,1.07,0)
			cyl(k,base,base+Vector3(0,.35,0),.32,TRIM,12)
			k.xf=Transform3D(Basis(Vector3.BACK,-.5),base+Vector3(0,.4,0))
			cbox(k,Vector3(-.85,0,0),Vector3(1.95,.24,.26),Color("e0a83a"),.03)
			k.xf=Transform3D()
			var tip=base+Vector3(0,.4,0)+Basis(Vector3.BACK,-.5)*Vector3(-1.78,0,0)
			cyl(k,tip,tip-Vector3(0,.9,0),.015,TRIM,4)
			cbox(k,tip-Vector3(0,.98,0),Vector3(.1,.14,.06),TRIM,.02)
			k.box(Vector3(cab_back+.6,roof+.1,0),Vector3(.2,.08,1.2),AMBER,true) # light bar
	for side in [-1.,1.]:k.box(Vector3(r+.15,.45,side*(hw-.25)),Vector3(.02,.4,.35),RUBBER,true) # mud flaps
# --- round props -------------------------------------------------------------
## 200 l steel drum: rolling hoops, recessed lid with chime, two bungs.
static func drum(k:DistrictFacade.Kit,at:Vector3,r:float,h:float,col:Color,label:bool):
	var hoop=col.darkened(.22);var lid=col.darkened(.12)
	var s=h/.93
	var prof=[[0.,0.],[r-.015,0.,col],[r,.02*s],[r,.3*s,hoop],[r+.012,.31*s],[r+.012,.335*s],[r,.345*s,col],
		[r,.6*s,hoop],[r+.012,.61*s],[r+.012,.635*s],[r,.645*s,col],[r,.905*s,lid],[r-.012,h],[r-.03,h],[r-.035,h-.02,lid.darkened(.1)],[0.,h-.02]]
	if label:prof=[[0.,0.],[r-.015,0.,col],[r,.02*s],[r,.3*s,hoop],[r+.012,.31*s],[r+.012,.335*s],[r,.345*s,Color("f1ede2")],
		[r,.6*s,hoop],[r+.012,.61*s],[r+.012,.635*s],[r,.645*s,col],[r,.905*s,lid],[r-.012,h],[r-.03,h],[r-.035,h-.02,lid.darkened(.1)],[0.,h-.02]]
	lathe(k,at,Basis(),prof,col,16)
	cyl(k,at+Vector3(r*.55,h-.02,0),at+Vector3(r*.55,h+.012,0),.035,TRIM,6)
	cyl(k,at+Vector3(-r*.5,h-.02,r*.2),at+Vector3(-r*.5,h+.008,r*.2),.022,TRIM,6)
## Wooden cask: bulging staves (alternating shades), iron hoops.
static func cask(k:DistrictFacade.Kit,at:Vector3,r:float,h:float,wood:Color):
	var iron=Color("4a4d50");var end=r*.82
	var prof=[[0.,.0],[end,0.,wood.darkened(.1)],[end,.015,iron],[end+.012,.05],[end+.02,.1,wood],[r*.95,.2*h,iron],[r*.97,.26*h,wood],[r,.42*h],[r,.58*h,iron],[r-.003,.62*h,wood],
		[r*.97,.74*h,iron],[r*.95,.8*h,wood],[end+.02,h-.1,iron],[end+.012,h-.05],[end,h-.015,wood.darkened(.1)],[end-.02,h-.015],[end-.025,h-.03,wood.darkened(.2)],[0.,h-.03]]
	lathe(k,at,Basis(),prof,wood,16,false,.08)
	cyl(k,at+Vector3(0,h*.5,r-.004),at+Vector3(0,h*.5,r+.012),.03,iron,6)
## Cable drum: plank flanges, cable windings, steel hub; axle along z.
static func spool(k:DistrictFacade.Kit,hs:int) -> AABB:
	var wood=Color(["b07c4a","8f6a44","a8865a"][hs%3]);var cable=[Color("2f3135"),Color("b5563e"),Color("2f5f8f")][hs%3]
	var c=Vector3(0,.7,0)
	for z in [-.35,.35]:
		var frame=Basis(Vector3.RIGHT,Vector3(0,0,signf(z)),Vector3.RIGHT.cross(Vector3(0,0,signf(z))))
		lathe(k,c+Vector3(0,0,z-signf(z)*.045),frame,[[.4,0.],[.68,0.],[.7,.02],[.7,.07],[.68,.09],[.16,.09,RIM.darkened(.2)],[.16,.11],[0.,.11]],wood,16,false,.07)
		for i in range(6):
			var a=TAU*i/6.;var p=c+Vector3(cos(a)*.24,sin(a)*.24,z+signf(z)*.05)
			k.box(p,Vector3(.04,.04,.03),RIM.darkened(.3),true)
	lathe(k,c+Vector3(0,0,-.3),Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),[[.4,0.],[.5,.0],[.52,.05],[.52,.55],[.5,.6],[.4,.6]],cable,16,false,.12)
	return AABB(Vector3(-.7,0,-.45),Vector3(1.4,1.4,.9))
## Big water tank lying on a skid: domed ends, moulded ribs, saddles, hatch,
## outlet valve; long along z.
static func water_tank(k:DistrictFacade.Kit,hs:int) -> AABB:
	var shell=Color(["3f7fbf","3f8a6a","c8ac7a"][hs%3]);var rib=shell.darkened(.12);var steel=Color("7f8a92")
	var c=Vector3(0,1.08,0);var R=.88;var half=2.2
	var prof=[[0.,-half],[.45,-half+.04],[.72,-half+.16],[R-.02,-half+.36],[R,-half+.5]]
	for i in range(5):
		var z=-1.4+i*.7
		prof.append_array([[R,z-.06,rib],[R+.025,z-.03],[R+.025,z+.03],[R,z+.06,shell]])
	prof.append_array([[R,half-.5],[R-.02,half-.36],[.72,half-.16],[.45,half-.04],[0.,half]])
	lathe(k,c,Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK)),prof,shell,18)
	# saddles and skid
	for z in [-1.35,0.,1.35]:
		k.box(Vector3(0,.26,z),Vector3(1.5,.32,.16),steel,true)
		k.box(Vector3(0,.48,z),Vector3(1.1,.14,.18),steel.darkened(.1),true)
	for side in [-1.,1.]:k.box(Vector3(side*.62,.07,0),Vector3(.16,.14,4.6),steel.darkened(.2),true)
	# top hatch, vent, outlet with valve wheel
	cyl(k,c+Vector3(0,R-.05,.6),c+Vector3(0,R+.1,.6),.26,shell.darkened(.05),14)
	cyl(k,c+Vector3(0,R+.1,.6),c+Vector3(0,R+.13,.6),.2,TRIM,14)
	cyl(k,c+Vector3(.15,R-.05,-.9),c+Vector3(.15,R+.22,-.9),.04,steel,8)
	cyl(k,c+Vector3(0,-.45,-half+.1),c+Vector3(0,-.45,-half-.25),.07,steel,8)
	cyl(k,c+Vector3(0,-.45,-half-.25),c+Vector3(0,-.25,-half-.25),.07,TAIL.darkened(.2),8)
	return AABB(Vector3(-.92,0,-2.45),Vector3(1.84,2.0,4.9))
## Loose junk tyre (InteractiveProp): low 12-sided torus, worn tread shades;
## axis along z, centred.
static func tyre(k:DistrictFacade.Kit):
	var frame=Basis(Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT.cross(Vector3.BACK))
	lathe(k,Vector3.ZERO,frame,[[.17,-.07],[.21,-.095],[.3,-.095],[.34,-.06],[.34,.06],[.3,.095],[.21,.095],[.17,.07],[.155,0.]],RUBBER,12,true,.1)
## Steel drum for the loose barrel (InteractiveProp, centred).
static func loose_drum(k:DistrictFacade.Kit,id:int):
	drum(k,Vector3(0,-.46,0),.345,.92,[Color("3f7fbf"),Color("e0a83a"),Color("c9503a")][id%3],id%4==1)
