extends SceneTree
# Grip geometry of every baked base, measured by casting rays from inside:
#  RIGHT: per 1 cm level the pistol grip's front / back face (z) and half width
#         (magazines included: pistols carry theirs in the grip).
#  TRIGGER: rays inside the guard opening toward the grip find the trigger blade.
#  LEFT: around the support marker, the handguard cross-section per 2 cm.
const BASES=["SMG"]
# A start point inside each grip (base-local), from the side renders.
const INSIDE={"AK":Vector3(0,-.11,-.232),"SMG":Vector3(0,-.12,-.05),"Pistol":Vector3(0,-.05,.0),"Revolver":Vector3(0,-.06,.012),"Revolver_Small":Vector3(0,-.07,.0),
	"Shotgun":Vector3(0,-.03,-.29),"ShortCannon":Vector3(0,-.02,-.27),"Sniper":Vector3(0,-.12,-.25),"Sniper_2":Vector3(0,-.12,-.255)}
func hit(faces:PackedVector3Array,from:Vector3,dir:Vector3) -> float:
	var best=INF
	for i in range(0,faces.size(),3):
		var r=Geometry3D.ray_intersects_triangle(from,dir,faces[i],faces[i+1],faces[i+2])
		if r==null:r=Geometry3D.ray_intersects_triangle(from,dir,faces[i],faces[i+2],faces[i+1])
		if r!=null:best=minf(best,from.distance_to(r))
	return best
func _initialize():
	for name in BASES:
		var gun:Node3D=GunModel.base_scene(name).instantiate();root.add_child(gun)
		var faces=PackedVector3Array()
		for m in gun.find_children("*","MeshInstance3D",true,false):
			var f=m.mesh.get_faces();for i in range(f.size()):faces.append(m.transform*f[i])
		var c:Vector3=INSIDE[name]
		print("== ",name," inside ",c," muzzle ",gun.get_node("Muzzle").position," left ",gun.get_node("LeftGrip").position)
		var top=c.y+hit(faces,c,Vector3.UP);var bottom=c.y-hit(faces,c,Vector3.DOWN)
		print("  grip column y %.4f .. %.4f"%[bottom,top])
		var y=top-.005
		while y>bottom:
			var from=Vector3(0,y,c.z)
			var front=hit(faces,from,Vector3(0,0,-1));var back=hit(faces,from,Vector3(0,0,1));var side=hit(faces,from,Vector3(1,0,0))
			if front<INF and back<INF:print("  RIGHT y=%.3f front=%.4f back=%.4f mid=%.4f halfx=%.4f"%[y,c.z-front,c.z+back,c.z+(back-front)*.5,side])
			y-=.01
		# Trigger: from ahead of the grip inside the guard opening, look back.
		var front_top=c.z-hit(faces,Vector3(0,top-.012,c.z),Vector3(0,0,-1))
		for k in range(0,9):
			var ty=top-.004-k*.005;var from=Vector3(0,ty,front_top-.08)
			var d=hit(faces,from,Vector3(0,0,1))
			if d<INF:print("  TRIGGER? y=%.3f first surface behind z=%.4f (grip front %.4f)"%[ty,from.z+d,front_top])
		# Support: handguard cross-section around the left marker.
		var left:Vector3=GunModel.HANDLES.get(name,{}).get("left",gun.get_node("LeftGrip").position)
		for dz in [-.06,-.03,0.,.03,.06]:
			var p=Vector3(0,left.y,left.z+dz)
			# start inside: move up until a downward ray from above hits.
			var up=hit(faces,p+Vector3(0,.2,0),Vector3.DOWN)
			var down=hit(faces,p+Vector3(0,-.2,0),Vector3.UP)
			var sx=hit(faces,p+Vector3(.2,0,0),Vector3.LEFT)
			print("  LEFT z=%.3f top=%.4f bottom=%.4f halfx=%.4f"%[p.z,p.y+.2-up if up<INF else 9.,p.y-.2+down if down<INF else -9.,.2-sx if sx<INF else -1.])
		gun.queue_free()
	quit()
