class_name FittedArmor
extends RefCounted
## 1.4.2 armour fitted to each hero. Rays cast outward from the spine find the
## hero's own torso surface (body and hip meshes, T pose), and the vest is lofted
## over it as one skinned mesh: every point takes the bone weights of the body
## surface under it, so the vest fits each outfit and body shape and moves with
## the same skeleton. Built once per hero and tier (a few hundred rays), then
## recoloured per team; one draw per armoured hero.
##  Tier 1 (light, +25): soft vest over chest, back and sides with arm holes,
##   team band along the top, hem trim, shoulder straps, a team chest patch.
##  Tier 2 (heavy, +50): thicker carrier reaching the belt, raised front and back
##   plates with a team stripe, three magazine pouches, shoulder pads.
const TORSO=["Root","Body","Hips","Abdomen","Torso","Chest"]
const SHELL=[Color("4b5a44"),Color("2f3540")]
const PLATE=Color("465061")
const POUCH=Color("59604a")
const FLAP=Color("454b3a")
const WEB=Color("262a31")
const TRIM=Color("1d2128")
const TEAM_KEY=Color(1,0,1) # placeholder recoloured per team
static var cache={}
static var bases={}
static var rigs={}
## The fitted vest for a built hero (a MeshInstance3D to put under its skeleton).
static func build(hero:HeroCharacter,level:int) -> MeshInstance3D:
	level=clampi(level,1,2)
	var body=body_of(hero)
	if body==null:return null
	var key=str([hero.role,level,hero.team,hero.outlined])
	if not cache.has(key):
		var base_key=str([hero.role,level])
		if not bases.has(base_key):
			# Shipped bakes (tools/bake_armor.gd) skip the ray fit at run time.
			var path=baked_path(hero.role,level)
			bases[base_key]=load(path) if ResourceLoader.exists(path) else make_mesh(hero,body,level)
		cache[key]=recolor(bases[base_key],HeroStyle.TEAM_MAIN[clampi(hero.team,0,1)],hero.outlined)
	if cache[key]==null:return null
	var node=MeshInstance3D.new();node.name="FittedArmor";node.mesh=cache[key];node.skin=body.skin;node.skeleton=NodePath("..")
	node.transform=body.transform
	node.set_surface_override_material(0,HeroStyle.toon_material(hero.outlined,.15))
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
static func baked_path(role:int,level:int) -> String:
	return "res://assets/heroes/armor/%s_%d.res" % [HeroCharacter.OUTFITS[clampi(role,0,5)],level]
static func recolor(base:ArrayMesh,team:Color,outlined:bool) -> ArrayMesh:
	if base==null:return null
	var arrays=base.surface_get_arrays(0);var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	for i in range(colors.size()):
		if colors[i].is_equal_approx(TEAM_KEY):colors[i]=team.srgb_to_linear()
	arrays[Mesh.ARRAY_COLOR]=colors
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return HeroStyle.with_smooth_normals(mesh) if outlined else mesh
# Triangles of every skinned part in the body's mesh space, with the body
# skin's bind indices: [a,b,c, weights a,b,c (bind->weight), dominant bones, ymin, ymax].
static func rig(hero:HeroCharacter,body:MeshInstance3D) -> Dictionary:
	if rigs.has(hero.role):return rigs[hero.role]
	var sk:Skeleton3D=hero.skeleton;var skin:Skin=body.skin
	var bind_of={};var at={}
	for i in range(skin.get_bind_count()):
		var n=skin.get_bind_name(i)
		if n=="":n=sk.get_bone_name(skin.get_bind_bone(i))
		bind_of[n]=i;at[n]=skin.get_bind_pose(i).affine_inverse().origin
	var tris=[]
	# The worn outfit only (a backpack or helmet is not part of the fit).
	for part in hero.meshes():
		if part.skin==null or not (str(part.name).ends_with("_Body") or str(part.name).ends_with("_Legs")):continue
		var names={}
		for i in range(part.skin.get_bind_count()):
			var n=part.skin.get_bind_name(i)
			names[i]=n if n!="" else sk.get_bone_name(part.skin.get_bind_bone(i))
		var to_body=body.transform.affine_inverse()*part.transform
		for s in range(part.mesh.get_surface_count()):
			var arr=part.mesh.surface_get_arrays(s)
			var v:PackedVector3Array=arr[Mesh.ARRAY_VERTEX];var b=arr[Mesh.ARRAY_BONES];var w=arr[Mesh.ARRAY_WEIGHTS];var idx=arr[Mesh.ARRAY_INDEX]
			if b==null or w==null or v.is_empty():continue
			var indexed=idx!=null and idx.size()>0
			var per=b.size()/v.size()
			var weights=[];var dominant=[];var points=[]
			for i in range(v.size()):
				var d={};var top="";var best=0.
				for k in range(per):
					var wt=float(w[i*per+k])
					if wt<=0.:continue
					var n=str(names.get(int(b[i*per+k]),""))
					if wt>best:best=wt;top=n
					if bind_of.has(n):d[bind_of[n]]=float(d.get(bind_of[n],0.))+wt
				weights.append(d);dominant.append(top);points.append(to_body*v[i])
			var count=idx.size() if indexed else v.size()
			for t in range(0,count,3):
				var i0=int(idx[t]) if indexed else t
				var i1=int(idx[t+1]) if indexed else t+1
				var i2=int(idx[t+2]) if indexed else t+2
				var a:Vector3=points[i0];var c1:Vector3=points[i1];var c2:Vector3=points[i2]
				tris.append([a,c1,c2,weights[i0],weights[i1],weights[i2],[dominant[i0],dominant[i1],dominant[i2]],minf(a.y,minf(c1.y,c2.y)),maxf(a.y,maxf(c1.y,c2.y))])
	var unit=absf(hero.model.scale.y*sk.transform.basis.get_scale().y*body.transform.basis.get_scale().y)
	rigs[hero.role]={"tris":tris,"at":at,"m":1./maxf(.0001,unit)}
	return rigs[hero.role]
static func body_of(hero:HeroCharacter) -> MeshInstance3D:
	for m in hero.meshes():
		if str(m.name).ends_with("_Body") and m.skin!=null:return m
	return null
## Body surface (mesh space, T pose) where a ray from inside leaves the parts
## dominated by `bones`; `from` when it misses.
static func surface(hero:HeroCharacter,body:MeshInstance3D,from:Vector3,dir:Vector3,bones:Array) -> Vector3:
	var h=cast(only(rig(hero,body)["tris"],bones),from,dir.normalized(),false)
	return from+dir.normalized()*h[0] if h[1]!=null else from
## `count` surface points around a level ring (angle 0 = front, +X = left);
## misses take the previous point's distance.
static func ring(hero:HeroCharacter,body:MeshInstance3D,centre:Vector3,bones:Array,count:int) -> Array:
	var tris=only(rig(hero,body)["tris"],bones);var points=[];var last=.12
	for i in range(count):
		var th=TAU*i/count;var dir=Vector3(sin(th),0.,cos(th))
		var h=cast(tris,centre,dir,true)
		if h[1]!=null:last=h[0]
		points.append(centre+dir*last)
	return points
static func point_on(points:Array,theta:float) -> Vector3:
	var f=wrapf(theta/TAU,0.,1.)*points.size();var i=int(f)%points.size()
	return Vector3(points[i]).lerp(points[(i+1)%points.size()],f-floorf(f))
static func only(tris:Array,allowed:Array) -> Array:
	return tris.filter(func(t):return t[6].all(func(n):return n in allowed))
# Farthest hit of a ray on the triangles: [distance, triangle] or [-1, null].
static func cast(tris:Array,from:Vector3,dir:Vector3,level_ray:bool) -> Array:
	var best=-1.;var hit=null
	for t in tris:
		if level_ray and (from.y<t[7] or from.y>t[8]):continue
		var p=Geometry3D.ray_intersects_triangle(from,dir,t[0],t[1],t[2])
		if p==null:continue
		var d=(p-from).dot(dir)
		if d>best:best=d;hit=t
	return [best,hit]
# Bone weights at a point of a triangle (barycentric blend of its corners).
static func weights_at(t:Array,p:Vector3) -> Dictionary:
	var v0:Vector3=t[1]-t[0];var v1:Vector3=t[2]-t[0];var v2:Vector3=p-t[0]
	var d00=v0.dot(v0);var d01=v0.dot(v1);var d11=v1.dot(v1);var d20=v2.dot(v0);var d21=v2.dot(v1)
	var den=d00*d11-d01*d01
	var bv=clampf((d11*d20-d01*d21)/den,0.,1.) if absf(den)>1e-12 else 0.
	var bw=clampf((d00*d21-d01*d20)/den,0.,1.) if absf(den)>1e-12 else 0.
	var bu=maxf(0.,1.-bv-bw)
	var out={}
	for pair in [[t[3],bu],[t[4],bv],[t[5],bw]]:
		for k in pair[0]:out[k]=float(out.get(k,0.))+pair[0][k]*pair[1]
	return out
static func top4(d:Dictionary) -> Array:
	var keys=d.keys();keys.sort_custom(func(a,b):return d[a]>d[b])
	var bones=PackedInt32Array([0,0,0,0]);var weights=PackedFloat32Array([0,0,0,0]);var sum=0.
	for k in range(mini(4,keys.size())):bones[k]=keys[k];weights[k]=d[keys[k]];sum+=d[keys[k]]
	if sum>0.:
		for k in range(4):weights[k]/=sum
	else:weights[0]=1.
	return [bones,weights]
# One armour sheet: a grid of rays (ray.call(a,b) -> [origin, direction], a and b
# in 0..1; `wrap` closes it around in a), lifted off the body from `inner` to
# `outer` with walls on its open edges. paint.call(a,b,wall) -> Color.
static func sheet(st:SurfaceTool,tris:Array,nu:int,nv:int,wrap:bool,level_ray:bool,ray:Callable,inner:float,outer:float,paint:Callable):
	var grid=[];var found=0
	for i in range(nu):
		var column=[]
		for j in range(nv):
			var a=float(i)/float(nu) if wrap else float(i)/float(nu-1);var b=float(j)/float(nv-1)
			var r=ray.call(a,b);var h=cast(tris,r[0],r[1],level_ray)
			column.append({"o":r[0],"d":r[1],"t":h[0],"w":weights_at(h[1],r[0]+r[1]*h[0]) if h[1]!=null else {},"a":a,"b":b,"fresh":false})
			if h[1]!=null:found+=1
		grid.append(column)
	if found==0:return
	# Misses (gaps between parts) take their neighbours' distance and weights.
	for pass_index in range(nu+nv):
		var missing=false
		for i in range(nu):
			for j in range(nv):
				var c=grid[i][j]
				if c["t"]>=0.:continue
				var sum=0.;var n=0;var w={}
				for o in [[1,0],[-1,0],[0,1],[0,-1]]:
					var ii=posmod(i+o[0],nu) if wrap else i+o[0];var jj=j+o[1]
					if ii<0 or ii>=nu or jj<0 or jj>=nv:continue
					var nb=grid[ii][jj]
					if nb["t"]>=0. and not nb["fresh"]:sum+=nb["t"];n+=1;w=nb["w"]
				if n>0:c["t"]=sum/n;c["w"]=w;c["fresh"]=true
				else:missing=true
		for column in grid:
			for c in column:c["fresh"]=false
		if not missing:break
	for column in grid:
		for c in column:
			var p:Vector3=c["o"]+c["d"]*maxf(c["t"],0.)
			c["hi"]=p+c["d"]*outer;c["lo"]=p+c["d"]*inner;c["bw"]=top4(c["w"])
	# Smooth normals from the lifted grid.
	for i in range(nu):
		for j in range(nv):
			var i0=posmod(i-1,nu) if wrap else maxi(i-1,0);var i1=posmod(i+1,nu) if wrap else mini(i+1,nu-1)
			var n:Vector3=(grid[i1][j]["hi"]-grid[i0][j]["hi"]).cross(grid[i][mini(j+1,nv-1)]["hi"]-grid[i][maxi(j-1,0)]["hi"]).normalized()
			if n.dot(grid[i][j]["d"])<0.:n=-n
			grid[i][j]["n"]=n if n.length()>.5 else grid[i][j]["d"]
	var cells=nu if wrap else nu-1
	for i in range(cells):
		var i1=(i+1)%nu
		for j in range(nv-1):
			var q=[grid[i][j],grid[i1][j],grid[i1][j+1],grid[i][j+1]]
			var outward:Vector3=q[0]["d"]+q[2]["d"]
			var color:Color=paint.call(q[0]["a"],(q[0]["b"]+q[3]["b"])*.5,false)
			var v=q.map(func(c):return [c,c["hi"],c["n"],color])
			face(st,[v[0],v[1],v[2]],outward);face(st,[v[0],v[2],v[3]],outward)
	# Walls on the open edges: [edge start, edge end, inner neighbour].
	var edges=[]
	for i in range(cells):
		var i1=(i+1)%nu
		edges.append([grid[i][0],grid[i1][0],grid[i][1]])
		edges.append([grid[i][nv-1],grid[i1][nv-1],grid[i][nv-2]])
	if not wrap:
		for j in range(nv-1):
			edges.append([grid[0][j],grid[0][j+1],grid[1][j]])
			edges.append([grid[nu-1][j],grid[nu-1][j+1],grid[nu-2][j]])
	for e in edges:
		var c0=e[0];var c1=e[1]
		var outward:Vector3=(c0["hi"]+c1["hi"])*.5-e[2]["hi"]
		var color:Color=paint.call(c0["a"],c0["b"],true)
		var normal=(c1["hi"]-c0["hi"]).cross(c0["d"]+c1["d"]).normalized()
		if normal.dot(outward)<0.:normal=-normal
		face(st,[[c0,c0["hi"],normal,color],[c1,c1["hi"],normal,color],[c1,c1["lo"],normal,color]],outward)
		face(st,[[c0,c0["hi"],normal,color],[c1,c1["lo"],normal,color],[c0,c0["lo"],normal,color]],outward)
# One triangle ([cell, position, normal, colour] x3) wound to face `outward`
# (Godot's front faces are clockwise: (c-a)x(b-a) points out).
static func face(st:SurfaceTool,verts:Array,outward:Vector3):
	var p0:Vector3=verts[0][1];var p1:Vector3=verts[1][1];var p2:Vector3=verts[2][1]
	if (p2-p0).cross(p1-p0).dot(outward)<0.:verts=[verts[0],verts[2],verts[1]]
	for v in verts:
		var bw=v[0]["bw"]
		st.set_bones(bw[0]);st.set_weights(bw[1]);st.set_color(v[3].srgb_to_linear());st.set_normal(v[2]);st.add_vertex(v[1])
static func make_mesh(hero:HeroCharacter,body:MeshInstance3D,level:int) -> ArrayMesh:
	var r=rig(hero,body);var at:Dictionary=r["at"];var m:float=r["m"]
	for need in ["Hips","Abdomen","Chest","Neck","Shoulder.L","Shoulder.R","UpperArm.L","UpperArm.R"]:
		if not at.has(need):return null
	var shell_tris=only(r["tris"],TORSO+["Shoulder.L","Shoulder.R"])
	if shell_tris.size()<20:return null
	var strap_tris=only(r["tris"],TORSO+["Neck","Shoulder.L","Shoulder.R"])
	var st=SurfaceTool.new();st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS);st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var heavy=level==2
	var thick=(.022 if not heavy else .034)*m
	var hips:Vector3=at["Hips"];var chest:Vector3=at["Chest"];var neck:Vector3=at["Neck"]
	var bottom=lerpf(hips.y,at["Abdomen"].y,.62) if not heavy else hips.y+.012*m
	var top_front=lerpf(chest.y,neck.y,.5);var top_side=chest.y-.075*m
	# The shell: rings from the hem up, lower at the sides (arm holes).
	var shell_ray=func(a:float,b:float) -> Array:
		var th=a*TAU
		var y=lerpf(bottom,lerpf(top_front,top_side,smoothstep(.42,.92,absf(sin(th)))),b)
		var z=lerpf(hips.z,chest.z,clampf(inverse_lerp(hips.y,chest.y,y),0.,1.))
		return [Vector3(chest.x,y,z),Vector3(sin(th),0.,cos(th))]
	var shell:Color=SHELL[level-1]
	var shell_paint=func(a:float,b:float,wall:bool) -> Color:
		if wall:return TEAM_KEY if b>.5 and not heavy else TRIM
		if b>.87:return TRIM if heavy else TEAM_KEY
		if b<.09:return TRIM
		return shell
	sheet(st,shell_tris,28,9,true,true,shell_ray,.003*m,thick,shell_paint)
	# Shoulder straps: rays fanned in the side plane from the chest over each shoulder.
	var half=absf(at["UpperArm.L"].x-chest.x)
	var web=func(a:float,b:float,wall:bool) -> Color:return WEB
	for side in [-1.,1.]:
		var x=chest.x+side*half*.5
		var strap_ray=func(a:float,b:float) -> Array:
			var phi=deg_to_rad(lerpf(-12.,192.,b))
			return [Vector3(x+(a-.5)*.045*m,chest.y,chest.z),Vector3(0.,sin(phi),cos(phi))]
		sheet(st,strap_tris,3,14,false,false,strap_ray,.002*m,thick+.009*m,web)
	if not heavy:
		# Team patch on the left chest.
		var patch=func(a:float,b:float,wall:bool) -> Color:return TEAM_KEY
		sheet(st,shell_tris,3,3,false,true,shell_part(shell_ray,deg_to_rad(9.),deg_to_rad(27.),.66,.8),thick-.002*m,thick+.006*m,patch)
		st.index();return st.commit()
	# Raised front and back plates with a team stripe.
	var plate=func(a:float,b:float,wall:bool) -> Color:
		if wall:return TRIM
		return TEAM_KEY if b>.62 and b<.82 else PLATE
	for centre in [0.,PI]:
		sheet(st,shell_tris,7,6,false,true,shell_part(shell_ray,centre-deg_to_rad(36.),centre+deg_to_rad(36.),.4,.96),thick-.002*m,thick+.02*m,plate)
	# Three magazine pouches on the belly (flap on top).
	var pouch=func(a:float,b:float,wall:bool) -> Color:
		if b>.7:return FLAP
		return POUCH.darkened(.12) if wall else POUCH
	for k in range(3):
		var c=(k-1)*deg_to_rad(25.)
		sheet(st,shell_tris,4,4,false,true,shell_part(shell_ray,c-deg_to_rad(10.5),c+deg_to_rad(10.5),.07,.33),thick-.002*m,thick+.05*m,pouch)
	# Shoulder pads over each shoulder cap (they move with the upper arm).
	var pad=func(a:float,b:float,wall:bool) -> Color:
		if wall:return TRIM
		return TEAM_KEY if a>.7 else PLATE
	for side in ["L","R"]:
		var s:Vector3=at["Shoulder."+side];var u:Vector3=at["UpperArm."+side]
		var axis=(u-s).normalized();var up=(Vector3.UP-axis*axis.dot(Vector3.UP)).normalized();var fwd=axis.cross(up)
		var pad_ray=func(a:float,b:float) -> Array:
			var phi=deg_to_rad(lerpf(-68.,68.,b))
			return [u+axis*lerpf(-.03,.075,a)*m,up*cos(phi)+fwd*sin(phi)]
		sheet(st,only(r["tris"],["Shoulder."+side,"UpperArm."+side,"Chest"]),5,6,false,false,pad_ray,.002*m,.024*m,pad)
	st.index();return st.commit()
# A rectangle of the shell: angles th0..th1 (radians), heights b0..b1 (0..1).
static func shell_part(shell_ray:Callable,th0:float,th1:float,b0:float,b1:float) -> Callable:
	return func(a:float,b:float) -> Array:return shell_ray.call(lerpf(th0,th1,a)/TAU,lerpf(b0,b1,b))
