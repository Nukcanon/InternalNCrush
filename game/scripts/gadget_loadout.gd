class_name GadgetLoadout
extends RefCounted
const FRAG=8
static func frag(p:Dictionary) -> bool:return int(p.gadget)==FRAG or (int(p.role)==0 and int(p.gadget)==1)
static func cluster(p:Dictionary) -> bool:return int(p.role)==0 and int(p.gadget)==1
static func count(p:Dictionary) -> int:return 2 if frag(p) or int(p.role)==3 else 3 if int(p.role)==4 else 1
static func reset(p:Dictionary):
	p.gadget_count=count(p);p.smoke=3 if int(p.role)==4 and int(p.gadget)==0 else 0;p.flash_count=3 if int(p.role)==4 and int(p.gadget)==1 else 0
static func label(p:Dictionary) -> String:
	if int(p.gadget)==9:return "해체 키트"
	if cluster(p):return "확산 파편 수류탄"
	if frag(p):return "파편 수류탄"
	if int(p.role)==4:return "섬광탄" if int(p.gadget)==1 else "연막탄"
	return Rules.GADGETS[int(p.role)]
static func mounted(p:Dictionary,crouch:bool) -> bool:return int(p.role)==2 and int(p.gadget)==0 and crouch and int(p.slot)<2
