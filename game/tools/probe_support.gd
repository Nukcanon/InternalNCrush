extends SceneTree
# Support-hand cross-sections: at several z along the handguard / pump, the
# lowest solid part's bottom and top (x = 0) and its half width at mid height.
const Z={"AK":[-.58,-.62,-.66,-.70,-.74],"SMG":[-.36,-.40,-.44,-.48,-.52],"Shotgun":[-.70,-.75,-.80,-.85,-.90],"ShortCannon":[-.52,-.56,-.60,-.64,-.68],
	"Sniper":[-.56,-.60,-.64,-.68,-.72],"Sniper_2":[-.56,-.60,-.64,-.68,-.72],"Pistol":[-.02,.0],"Revolver":[-.02],"Revolver_Small":[-.02]}
func hit(faces:PackedVector3Array,from:Vector3,dir:Vector3) -> float:
	var best=INF
	for i in range(0,faces.size(),3):
		var r=Geometry3D.ray_intersects_triangle(from,dir,faces[i],faces[i+1],faces[i+2])
		if r==null:r=Geometry3D.ray_intersects_triangle(from,dir,faces[i],faces[i+2],faces[i+1])
		if r!=null and from.distance_to(r)>.0005:best=minf(best,from.distance_to(r))
	return best
func _initialize():
	for name in Z:
		var gun:Node3D=GunModel.base_scene(name).instantiate();root.add_child(gun)
		var faces=PackedVector3Array()
		for m in gun.find_children("*","MeshInstance3D",true,false):
			if m.name=="Magazine" and not name in ["Pistol","Revolver","Revolver_Small"]:continue
			var f=m.mesh.get_faces();for i in range(f.size()):faces.append(m.transform*f[i])
		print("== ",name)
		for z in Z[name]:
			var below=Vector3(0,-.5,z);var d=hit(faces,below,Vector3.UP)
			if d==INF:print("  z=%.2f nothing"%z);continue
			var bottom=below.y+d;var top=bottom+.002+hit(faces,Vector3(0,bottom+.002,z),Vector3.UP)
			var mid=(bottom+top)*.5;var half=hit(faces,Vector3(0,mid,z),Vector3.RIGHT)
			var above=hit(faces,Vector3(0,top+.002,z),Vector3.UP)
			print("  z=%.2f bottom=%.4f top=%.4f centre=%.4f halfy=%.4f halfx=%.4f  next solid above +%.3f"%[z,bottom,top,mid,(top-bottom)*.5,half,above])
		gun.queue_free()
	quit()
