class_name MapRegions
extends RefCounted
## 1.4.6 (the user): one map is split into regions, and windows, doors and
## props change from region to region. Regions follow the map's own shape:
## a centre and three sectors around it on each side. Team maps (half-turn
## images) give both halves the same region at mirrored points, so neither
## team's side looks different from the other's; defusal maps use six sectors.
const COUNT=7
static func symmetric(index:int) -> bool:return index<19 or index==31
## Region 0..COUNT-1 of a world point (x, z) on map `index` of half size `bounds`.
static func region(index:int,pos:Vector3,bounds:Vector2) -> int:
	var p=Vector2(pos.x/maxf(1.,bounds.x),pos.z/maxf(1.,bounds.y))
	if p.length()<.3:return 0
	if symmetric(index):
		if p.y<0. or (is_zero_approx(p.y) and p.x<0.):p=-p
		var a=atan2(p.y,p.x) # 0..PI
		return 1+clampi(int(a/(PI/3.)),0,2)+(3 if p.length()>.72 else 0)
	var b=fposmod(atan2(p.y,p.x),TAU)
	return 1+clampi(int(b/(TAU/6.)),0,5)
