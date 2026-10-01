extends SceneTree
# Hand/arm review: first person (right and left handed) for guns, reloads and
# held gear, and third-person close-ups (front and side) of the same holds.
# Args: optional filter substrings (only matching labels are captured).
# Output: validation/hands2/.
var g:Node
var out="res://../validation/hands2/"
var only:Array=[]
func _initialize():call_deferred("run")
func wanted(label:String) -> bool:
	if only.is_empty():return true
	for f in only:
		if f in label:return true
	return false
func shot(label:String):
	g.ui.refresh()
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
# --- Grip audit: hand / finger bone points inside the gun's meshes -----------
# Ray parity against each mesh of the item (world triangles); a point on the
# bone line inside a closed part means that finger passes through the gun.
func item_triangles(item:Node3D) -> Array:
	var sets=[]
	for m in item.find_children("*","MeshInstance3D",true,false):
		if not m.is_visible_in_tree() or m.mesh==null:continue
		var faces:PackedVector3Array=m.mesh.get_faces();var xf:Transform3D=m.global_transform
		var tris=PackedVector3Array();tris.resize(faces.size())
		for i in range(faces.size()):tris[i]=xf*faces[i]
		sets.append(tris)
	return sets
func inside(sets:Array,p:Vector3) -> bool:
	var d=Vector3(.5774,.6123,.5401).normalized()
	for tris in sets:
		var hits=0
		for i in range(0,tris.size(),3):
			var e1=tris[i+1]-tris[i];var e2=tris[i+2]-tris[i];var h=d.cross(e2);var det=e1.dot(h)
			if absf(det)<1e-10:continue
			var f=1./det;var s=p-tris[i];var u=f*s.dot(h)
			if u<0. or u>1.:continue
			var q=s.cross(e1);var v=f*d.dot(q)
			if v<0. or u+v>1.:continue
			if f*e2.dot(q)>1e-5:hits+=1
		if hits%2==1:return true
	return false
static func closest_on_triangle(p:Vector3,a:Vector3,b:Vector3,c:Vector3) -> Vector3:
	var ab=b-a;var ac=c-a;var ap=p-a
	var d1=ab.dot(ap);var d2=ac.dot(ap)
	if d1<=0. and d2<=0.:return a
	var bp=p-b;var d3=ab.dot(bp);var d4=ac.dot(bp)
	if d3>=0. and d4<=d3:return b
	var vc=d1*d4-d3*d2
	if vc<=0. and d1>=0. and d3<=0.:return a+ab*(d1/(d1-d3))
	var cp=p-c;var d5=ab.dot(cp);var d6=ac.dot(cp)
	if d6>=0. and d5<=d6:return c
	var vb=d5*d2-d1*d6
	if vb<=0. and d2>=0. and d6<=0.:return a+ac*(d2/(d2-d6))
	var va=d3*d6-d5*d4
	if va<=0. and d4-d3>=0. and d5-d6>=0.:return b+(c-b)*((d4-d3)/((d4-d3)+(d5-d6)))
	var denom=1./(va+vb+vc);return a+ab*(vb*denom)+ac*(vc*denom)
func depth(sets:Array,p:Vector3) -> float:
	var best=INF
	for tris in sets:
		for i in range(0,tris.size(),3):
			if absf(tris[i].x-p.x)>.05 and absf(tris[i+1].x-p.x)>.05 and absf(tris[i+2].x-p.x)>.05:continue
			best=minf(best,p.distance_to(closest_on_triangle(p,tris[i],tris[i+1],tris[i+2])))
	return best
func hand_points(h:HeroCharacter,side:String) -> Array:
	var pts=[]
	var wrist=h.bone_world(h.bone["Wrist."+side])
	var chains:Dictionary=HeroIK.finger_chains(h,side)
	for finger in chains:
		var bones:Array=chains[finger]
		for i in range(bones.size()):
			var o=h.bone_world(bones[i]).origin
			var nxt=h.bone_world(bones[i+1]).origin if i+1<bones.size() else h.bone_world(bones[i])*Vector3(0,HeroIK.TIP.get(finger,.028),0)
			if i==0:pts.append([finger+"0",wrist.origin.lerp(o,.5)])
			for k in [0.,.5]:pts.append([finger+str(i+1),o.lerp(nxt,k)])
		pts.append([finger+"tip",h.bone_world(bones[bones.size()-1])*Vector3(0,HeroIK.TIP.get(finger,.028)*.8,0)])
	return pts
func a_cam_local(p:Vector3) -> Vector3:return g.actors[1].camera.to_local(p).snapped(Vector3.ONE*.01)
func audit(h:HeroCharacter,item:Node3D,label:String):
	var sets=item_triangles(item);var line="AUDIT "+label
	if item is GunModel:
		var g=item.right_grip.global_position
		print("MAG ",label," node=",item.magazine," visible=",item.magazine.is_visible_in_tree() if item.magazine else false," local=",item.magazine.position if item.magazine else null," rest=",item.mag_rest.origin," aabb=",(item.magazine.get_aabb() if item.magazine is MeshInstance3D else "-") if item.magazine else "-"," cam=",(a_cam_local(item.magazine.global_position) if item.magazine else "-"))
		line+=" sanity(grip_in=%s far_out=%s)"%[str(inside(sets,g)),str(inside(sets,g+Vector3(0,3,0)))]
	for side in ["R","L"]:
		var bad=[];var worst=0.
		# The baked field (winding number) confirms inside points; single-ray
		# parity alone misreads open meshes.
		var g=item.grip(side) if item is GunModel else null
		var c=GripField.contact(item,g.global_transform) if g else {}
		var to_g=Transform3D(g.global_transform.basis.orthonormalized(),g.global_transform.origin).affine_inverse() if g else Transform3D()
		# held gear: its own baked field, in the holder's space (1.4.5)
		var gear_field=GripField.lookup(str(item.get_meta("grip_field_id",""))) if not item is GunModel else {}
		if side=="R" and not item is GunModel:line+=" field=%s(%s)"%["yes" if not gear_field.is_empty() else "no",str(item.get_meta("grip_field_id","-"))]
		for pt in hand_points(h,side):
			if inside(sets,pt[1]):
				var fd=GripField.distance(c,to_g*pt[1]) if not c.is_empty() else -1.
				if not gear_field.is_empty():fd=GripField.sample(gear_field,item.global_transform.affine_inverse()*pt[1])*absf(item.global_transform.basis.get_scale().y)
				if fd>0.:continue
				if not gear_field.is_empty():
					worst=maxf(worst,-fd)
					if -fd>.004:bad.append("%s:%.0fmm"%[pt[0],-fd*1000.])
					continue
				var dd=depth(sets,pt[1]);worst=maxf(worst,dd)
				if dd>.004:bad.append("%s:%.0fmm"%[pt[0],dd*1000.])
		line+=" %s_deep=%d(max %.1fmm)%s"%[side,bad.size(),worst*1000.,str(bad) if not bad.is_empty() else ""]
	if item is GunModel:
		var shapes:Dictionary=item.get_meta("grip_shapes",{})
		if shapes.has("R") and shapes.R.has("trigger"):
			var handle=item.right_grip.global_transform;var ws=HeroIK.world_shape(handle,"pistol",shapes.R)
			var chain:Array=HeroIK.finger_chains(h,"R").Index
			var tip=h.bone_world(chain[chain.size()-1])*Vector3(0,.02,0)
			var to_h=Transform3D(handle.basis.orthonormalized(),handle.origin).affine_inverse()
			line+=" trigger=%.3f"%(to_h*tip).distance_to(ws.trigger)
			if "fingers" in only:
				# Handle frame (y up the grip, -z forward): the trigger and each finger's knuckle / joints / tip.
				var fl="FINGERS "+label+" trigger=%s"%str(Vector3(ws.trigger).snapped(Vector3.ONE*.001))
				var chains:Dictionary=HeroIK.finger_chains(h,"R")
				for f in ["Index","Middle","Ring","Pinky","Thumb"]:
					if not chains.has(f):continue
					var pts=[]
					for b in chains[f]:pts.append((to_h*h.bone_world(b).origin).snapped(Vector3.ONE*.001))
					pts.append((to_h*(h.bone_world(chains[f][-1])*Vector3(0,HeroIK.TIP.get(f,.028),0))).snapped(Vector3.ONE*.001))
					fl+=" | %s %s"%[f,str(pts)]
				print(fl)
		for side in ["R","L"]:
			var g=item.grip(side)
			if g:line+=" %s_wrist_to_grip=%.3f"%[side,h.bone_world(h.bone["Wrist."+side]).origin.distance_to(g.global_position)]
	print(line)
# The first-person view model seen from its right side and from below-front
# (a temporary camera; the view body keeps its pose from the last frame).
func side_shot(a,label:String):
	var cam=Camera3D.new();root.add_child(cam);cam.fov=40.
	var focus:Vector3=a.view_weapon.global_transform*(a.view_weapon.right_grip.position*a.view_weapon.base.scale+Vector3(0,0,-.12))
	var basis:Basis=a.camera.global_basis
	cam.global_position=focus+basis.x*.75+basis.y*.05+basis.z*.05;cam.look_at(focus,basis.y);cam.current=true
	for i in range(2):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
	cam.global_position=focus-basis.x*.75+basis.y*.05+basis.z*.05;cam.look_at(focus,basis.y)
	for i in range(2):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+"-left.png")
	a.camera.current=true;cam.queue_free()
# 1.4.4 joint report: shoulder stretch (m), elbow bend, wrist bend and forearm
# roll (deg) per arm; hyper-extended finger joints (rotation past straight).
func arm_metrics(h:HeroCharacter) -> String:
	var out=""
	for sd in ["L","R"]:
		var u=h.bone_world(h.bone["UpperArm."+sd]);var l=h.bone_world(h.bone["LowerArm."+sd]);var w=h.bone_world(h.bone["Wrist."+sd])
		var elbow=rad_to_deg((u.origin-l.origin).angle_to(w.origin-l.origin))
		var local:Quaternion=(l.basis.get_rotation_quaternion().inverse()*w.basis.get_rotation_quaternion()).normalized()
		if local.w<0.:local=-local
		var roll=rad_to_deg(absf(wrapf(2.*atan2(local.y,local.w),-PI,PI)))
		var twist=Quaternion(0.,local.y,0.,local.w).normalized() if absf(local.y)>1e-6 else Quaternion.IDENTITY
		var bend=rad_to_deg((twist.inverse()*local).normalized().get_angle())
		if bend>180.:bend=360.-bend
		var hyper=0
		for entry in HeroIK.fingers_of(h,sd):
			if entry[2]<2:continue
			var rest:Quaternion=h.skeleton.get_bone_rest(entry[0]).basis.get_rotation_quaternion()
			var d:Quaternion=(rest.inverse()*h.skeleton.get_bone_pose_rotation(entry[0])).normalized()
			# flexion is about -X: a positive x component means bent backward
			if d.x>.02:hyper+=1
		out+=" %s(stretch=%.2f elbow=%.0f wrist=%.0f roll=%.0f hyper=%d)"%[sd,float(h.get_meta("fp_stretch_"+sd,0.)),elbow,bend,roll,hyper]
		if "debug" in only:
			var cam=h.get_meta("fp_camera",null)
			if cam is Camera3D:
				var cb:Basis=cam.global_basis.inverse()
				out+=" [%s fore=%s hand_y=%s hand_z=%s]"%[sd,str((cb*(w.origin-l.origin).normalized()).snapped(Vector3.ONE*.01)),str((cb*w.basis.y.normalized()).snapped(Vector3.ONE*.01)),str((cb*w.basis.z.normalized()).snapped(Vector3.ONE*.01))]
	return out
# 1.4.5: girth of the posed first-person arm (skinned on the CPU) along
# upper-arm joint -> elbow -> wrist, 12 bins, metres (world).
func posed_profile(h:HeroCharacter,sd:String) -> String:
	var arms:MeshInstance3D=h.skeleton.get_node_or_null("FPArms")
	if arms==null or arms.mesh==null or arms.skin==null:return "-"
	var sk=h.skeleton;var skin:Skin=arms.skin;var mats=[];var names=[]
	for b in range(skin.get_bind_count()):
		var bone=skin.get_bind_bone(b)
		if skin.get_bind_name(b)!="":bone=sk.find_bone(skin.get_bind_name(b))
		mats.append(sk.global_transform*sk.get_bone_global_pose(bone)*skin.get_bind_pose(b));names.append(sk.get_bone_name(bone))
	var a:Vector3=h.bone_world(h.bone["UpperArm."+sd]).origin;var e:Vector3=h.bone_world(h.bone["LowerArm."+sd]).origin;var w:Vector3=h.bone_world(h.bone["Wrist."+sd]).origin
	var la=a.distance_to(e);var lb=e.distance_to(w);var bins=[];for i in range(12):bins.append([0.,0])
	for s in range(arms.mesh.get_surface_count()):
		var arr=arms.mesh.surface_get_arrays(s);var verts:PackedVector3Array=arr[Mesh.ARRAY_VERTEX];var bones=arr[Mesh.ARRAY_BONES];var weights=arr[Mesh.ARRAY_WEIGHTS]
		var per=bones.size()/maxi(1,verts.size())
		for i in range(verts.size()):
			var aw=0.;var p=Vector3.ZERO
			for k in range(per):
				var wgt=weights[i*per+k]
				if wgt<=0.:continue
				p+=(mats[bones[i*per+k]]*verts[i])*wgt
				var bn=str(names[bones[i*per+k]])
				if bn in ["UpperArm."+sd,"LowerArm."+sd] or (bn.begins_with("ForeTwist") and bn.ends_with("."+sd)):aw+=wgt
			if aw<.5:continue
			var t1=clampf((p-a).dot(e-a)/(la*la),0.,1.);var t2=clampf((p-e).dot(w-e)/(lb*lb),0.,1.)
			var p1=a+(e-a)*t1;var p2=e+(w-e)*t2;var d1=p.distance_to(p1);var d2=p.distance_to(p2)
			var u=(t1*la if d1<d2 else la+t2*lb)/(la+lb)
			var bi=clampi(int(u*12.),0,11);bins[bi][0]+=minf(d1,d2);bins[bi][1]+=1
	var scale=absf(h.global_basis.get_scale().y)
	var out="%s elbow@%.0f%%:"%[sd,la/(la+lb)*100.]
	for x in bins:out+=" %.3f"%(x[0]/x[1]/scale*HeroCharacter.FP_BODY_SCALE/HeroCharacter.FP_BODY_SCALE if x[1]>0 else -1.)
	return out
# Close-ups of each hand from the eye (narrow lens) and the whole view model
# from the right side.
# 1.4.5: the firing index fingertip against the trigger (gun-base space, m;
# the trigger point of GunModel.handles / the gun's own grip shape).
func trigger_report(vb:HeroCharacter,label:String):
	if not is_instance_valid(vb.held) or not vb.held is GunModel:return
	var gm:GunModel=vb.held;var hd:Dictionary=GunModel.hand_set(gm.look)
	if not hd.has("trigger"):return
	var ch:Dictionary=HeroIK.finger_chains(vb,"R");var ib:Array=ch.Index
	var tipw:Vector3=vb.bone_world(ib[-1])*Vector3(0,HeroIK.TIP.Index,0)
	var to_base:Transform3D=gm.base.global_transform.affine_inverse()
	var d:Vector3=to_base*tipw-Vector3(hd.trigger)
	# splay between neighbouring fingers (degrees between their first-bone
	# directions) and each finger's least gap to the gun surface (m)
	var dirs={};var gaps={}
	var contact=GripField.contact(gm,gm.right_grip.global_transform)
	for f in ["Index","Middle","Ring","Pinky"]:
		var bs:Array=ch[f];dirs[f]=(vb.bone_world(bs[2]).origin-vb.bone_world(bs[1]).origin).normalized()
		var g=INF
		for b in bs.slice(1):
			if not contact.is_empty():g=minf(g,GripField.distance(contact,gm.right_grip.global_transform.affine_inverse()*vb.bone_world(b).origin))
		gaps[f]=g
	# neighbouring fingers' second joints apart (mm, world): about a finger's
	# width when they lie together
	var j2=func(f:String) -> Vector3:return vb.bone_world(ch[f][2]).origin
	var j3=func(f:String) -> Vector3:return vb.bone_world(ch[f][3]).origin
	var splay="M-R %.0f/%.0f R-P %.0f/%.0f mm"%[j2.call("Middle").distance_to(j2.call("Ring"))*1000.,j3.call("Middle").distance_to(j3.call("Ring"))*1000.,j2.call("Ring").distance_to(j2.call("Pinky"))*1000.,j3.call("Ring").distance_to(j3.call("Pinky"))*1000.]
	print("TRIGGER %s base=%s tip-trigger=%s |d|=%.3f handle=%s splay %s gaps M %.3f R %.3f P %.3f"%[label,str(gm.look.get("base","")),str(d.snapped(Vector3.ONE*.002)),d.length(),str((to_base*gm.right_grip.global_position).snapped(Vector3.ONE*.005)),splay,gaps.Middle,gaps.Ring,gaps.Pinky])
# [index tip to trigger (m), how far the middle finger rises above the guard
# bar inside the guard's span (m, <= 0 is clear)] in gun-base space.
func finger_fit(vb:HeroCharacter,gm:GunModel,hd:Dictionary) -> Array:
	var to_base:Transform3D=gm.base.global_transform.affine_inverse();var t:Vector3=hd.trigger
	var ch:Dictionary=HeroIK.finger_chains(vb,"R")
	var tip:Vector3=to_base*(vb.bone_world(ch.Index[-1])*Vector3(0,HeroIK.TIP.Index,0))
	var bar=t.y-HeroIK.GUARD_DROP;var over=-INF
	var mids:Array=ch.Middle;var pts=[]
	for b in mids:pts.append(to_base*vb.bone_world(b).origin)
	pts.append(to_base*(vb.bone_world(mids[-1])*Vector3(0,HeroIK.TIP.get("Middle",.03),0)))
	for q in pts:
		if q.z>t.z-.035 and q.z<t.z+.03:over=maxf(over,q.y-bar)
	return [tip.distance_to(t),over if over>-INF else -1.]
func closeups(a,label:String):
	var cam=Camera3D.new();root.add_child(cam);cam.fov=28.
	var vb:HeroCharacter=a.view_body
	for sd in ["L","R"]:
		var focus:Vector3=vb.bone_world(vb.bone["Wrist."+sd]).origin
		var chains:Dictionary=HeroIK.finger_chains(vb,sd)
		if chains.has("Middle"):focus=focus.lerp(vb.bone_world(chains.Middle[1]).origin,.6)
		cam.global_position=a.camera.global_position;cam.look_at(focus,a.camera.global_basis.y);cam.current=true
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+label+"-hand"+sd+".png")
	if "trigger" in only:trigger_report(vb,label)
	if "thumbprobe" in only and is_instance_valid(vb.held):
		# Where the support thumb would point (gun space, -z forward) for a sweep
		# of its base flexion with the pinch joints.
		var chains:Dictionary=HeroIK.finger_chains(vb,"L");var sk=vb.skeleton
		var wrist:Transform3D=vb.bone_world(vb.bone["Wrist.L"]);var to_gun:Transform3D=vb.held.global_transform.affine_inverse()
		var line="THUMBPROBE "+label
		for a0 in [-1.2,-.9,-.6,-.3,0.,.3,.5]:
			var frames:Array=HeroIK.finger_frames(sk,chains.Thumb,[a0,HeroIK.THUMB_PINCH[1],HeroIK.THUMB_PINCH[2]])
			var base:Vector3=to_gun*(wrist*frames[0].origin);var tip:Vector3=to_gun*(wrist*(frames[2]*Vector3(0,HeroIK.TIP.Thumb,0)))
			line+=" a0=%.1f dir=%s"%[a0,str((tip-base).normalized().snapped(Vector3.ONE*.01))]
		# Last thumb segment direction (gun space) for a sweep of the tip joint,
		# the base and middle joints as in the loading pose.
		line+=" | tip joint:"
		for a2 in [-1.2,-.6,0.,.6,1.2]:
			var fr:Array=HeroIK.finger_frames(sk,chains.Thumb,[HeroIK.THUMB_LOAD[0],HeroIK.THUMB_LOAD[1],a2])
			line+=" a2=%.1f seg=%s"%[a2,str((to_gun.basis*(wrist.basis*fr[2].basis.y)).normalized().snapped(Vector3.ONE*.01))]
		var mid:Array=HeroIK.finger_frames(sk,chains.Thumb,[HeroIK.THUMB_LOAD[0],HeroIK.THUMB_LOAD[1],0.])
		line+=" | thumb (straight) dir=%s"%str((to_gun.basis*(wrist.basis*mid[1].basis.y)).normalized().snapped(Vector3.ONE*.01))
		var ib:Vector3=to_gun*(wrist*HeroIK.finger_frames(sk,chains.Index,[0.,0.,0.,0.])[0].origin);var it:Vector3=to_gun*(wrist*(HeroIK.finger_frames(sk,chains.Index,[0.,0.,0.,0.])[3]*Vector3(0,HeroIK.TIP.Index,0)))
		line+=" | straight index dir=%s palm_normal(gun)=%s hand_y(gun)=%s"%[str((it-ib).normalized().snapped(Vector3.ONE*.01)),str((to_gun.basis*wrist.basis.z).normalized().snapped(Vector3.ONE*.01)),str((to_gun.basis*wrist.basis.y).normalized().snapped(Vector3.ONE*.01))]
		print(line)
	if "thumbsweep" in only and is_instance_valid(vb.held):
		# Firing thumb: tip (gun space, x right / y up / -z forward) and its
		# clearance from the gun's surface for a sweep of the three joints.
		var chains:Dictionary=HeroIK.finger_chains(vb,"R");var sk=vb.skeleton
		var wrist:Transform3D=vb.bone_world(vb.bone["Wrist.R"]);var to_gun:Transform3D=vb.held.global_transform.affine_inverse()
		var model:GunModel=vb.held if vb.held is GunModel else null
		var field=GripField.contact(model,model.right_grip.global_transform) if model else {}
		var rows=[]
		for a0 in [-.9,-.6,-.3,0.,.3,.6,.9,1.2]:
			for a1 in [0.,.4,.8,1.2]:
				for a2 in [0.,.5,1.]:
					var fr:Array=HeroIK.finger_frames(sk,chains.Thumb,[a0,a1,a2])
					var tip:Vector3=wrist*(fr[2]*Vector3(0,HeroIK.TIP.Thumb,0))
					var clear=INF
					for k in range(3):
						var p:Vector3=wrist*fr[k].origin
						if not field.is_empty():clear=minf(clear,GripField.distance(field,model.right_grip.global_transform.affine_inverse()*p))
					var g:Vector3=to_gun*tip
					rows.append([a0,a1,a2,g,clear])
		for r in rows:
			if r[3].y>-.02 and r[4]>-.004:print("THUMBSWEEP a=[%.1f,%.1f,%.1f] tip(gun)=%s clear=%.3f"%[r[0],r[1],r[2],str(Vector3(r[3]).snapped(Vector3.ONE*.005)),r[4]])
	if "loadhand" in only:
		# The loading (support) hand from above-front and from the left side.
		var focus:Vector3=vb.bone_world(vb.bone["Wrist.L"]).origin
		var chains:Dictionary=HeroIK.finger_chains(vb,"L")
		if chains.has("Index"):focus=focus.lerp(vb.bone_world(chains.Index[2]).origin,.7)
		var basis:Basis=a.camera.global_basis
		cam.fov=35.
		cam.global_position=focus+basis.y*.28-basis.z*.12-basis.x*.10;cam.look_at(focus,-basis.z)
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+label+"-loadtop.png")
		cam.global_position=focus-basis.x*.30+basis.y*.08-basis.z*.08;cam.look_at(focus,basis.y)
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+label+"-loadleft.png")
	if is_instance_valid(vb.held):
		var focus:Vector3=vb.held.global_position
		if vb.held is GunModel:focus=vb.held.global_transform*(vb.held.right_grip.position*vb.held.base.scale+Vector3(0,0,-.05))
		var basis:Basis=a.camera.global_basis
		cam.fov=30.
		# Firing hand from the right, close.
		cam.global_position=focus+basis.x*.45+basis.y*.02-basis.z*.02;cam.look_at(focus,basis.y)
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+label+"-grip.png")
		# From below-front (the trigger guard side).
		cam.global_position=focus+basis.x*.25-basis.y*.30-basis.z*.30;cam.look_at(focus,basis.y)
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+label+"-gripfront.png")
		cam.fov=45.
		cam.global_position=focus+basis.x*.9+basis.y*.1+basis.z*.15;cam.look_at(focus,basis.y)
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+label+"-side.png")
		cam.global_position=focus-basis.x*.9+basis.y*.1+basis.z*.15;cam.look_at(focus,basis.y)
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+label+"-sideL.png")
	a.camera.current=true;cam.queue_free()
func settle(actors:Array,frames:int=24):
	for i in range(frames):
		for a in actors:a.visual(1./30.,g.players[a.pid],g.clock)
		await process_frame
func reset(p:Dictionary):
	p.slot=0;p.cooking=0;p.erase("grenade_started");p.erase("throw_until");p.placing="";p.erase("melee_started");p.gadget_count=3;p.owned_gadget=true;p.reload=0.
func equip(a,p:Dictionary,role:int,slot:int,item:String,gadget:int=-1):
	reset(p);p.role=role;p.slot=slot
	if slot==0:p.primary=item
	elif slot==1:p.secondary=item
	if gadget>=0:p.gadget=gadget
	a.shown_weapon="";a.set_team(0)
func reload_at(p:Dictionary,wid:String,phase:float):
	var w=Catalog.get_weapon(wid);p.reload_tactical=false;p.reload_weapon=wid;p.mag[wid]=0
	var d=MagazineReload.duration(w);p.reload_count=int(w.mag);p.reload_capacity=int(w.mag)
	p.reload=g.clock+d*(1.-phase);p.reload_started=g.clock-d*phase
func run():
	for arg in OS.get_cmdline_user_args():only.append(arg)
	HeroIK.debug_contact="debugcontact" in only
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=PracticeLayout.INDEX
	g.profile.graphics_auto=false;g.profile.merge(GraphicsOptions.PRESETS[1],true);GraphicsOptions.apply(g)
	g.build_world();g.add_player(1,"PLAYER","hands_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=0;p.team=0;p.hand=1
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,18.);a.reset_view(0);await physics_frame
	var aim=func(on:bool):a.input_state.ads=on;a.aim_progress=1. if on else 0.;a.ads_blend=1. if on else 0.
	# [label, role, slot, item, gadget, extra] extra: "aim", "reload:<phase>", "cook"
	var cases=[["rifle-hip",0,0,"a1",-1,""],["rifle-aim",0,0,"a1",-1,"aim"],["rifle-reload20",0,0,"a1",-1,"reload:.2"],["rifle-reload45",0,0,"a1",-1,"reload:.45"],["rifle-reload70",0,0,"a1",-1,"reload:.7"],["rifle-reload90",0,0,"a1",-1,"reload:.9"],["pistol-reload45",0,1,"pistol",-1,"reload:.45"],["pistol-reload90",0,1,"pistol",-1,"reload:.9"],["shotgun-reload50",3,0,"e1",-1,"reload:.5"],["quad-reload30",2,0,"h5",-1,"reload:.3"],
		["smg-hip",0,0,"a2",-1,""],["shotgun-hip",3,0,"e1",-1,""],["sniper-hip",1,0,"r1",-1,""],["lmg-hip",2,0,"h1",-1,""],
		["pistol-hip",0,1,"pistol",-1,""],["pistol-aim",0,1,"pistol",-1,"aim"],["dual-hip",4,1,"dual_pistols",-1,""],
		["comet-hip",2,0,"h4",-1,""],["comet-reload45",2,0,"h4",-1,"reload:.45"],["comet-reload85",2,0,"h4",-1,"reload:.85"],
		["quad-reload60",2,0,"h5",-1,"reload:.6"],["grenade-cook",0,2,"",1,"cook"],["medkit",5,2,"",0,""],["plate",0,2,"",0,""],
		["tether",3,0,"remote",-1,""],["laser-hip",2,0,"h6",-1,""],["laser-fire",2,0,"h6",-1,"beam"],["laser-reload20",2,0,"h6",-1,"reload:.2"],["laser-reload45",2,0,"h6",-1,"reload:.45"],["laser-reload70",2,0,"h6",-1,"reload:.7"],["fix",3,1,"repair",-1,""],["link",5,0,"m1",-1,""],["link-aim",5,0,"m1",-1,"aim"],["link-heal",5,0,"m1",-1,"heal"],
		["smg-reload45",0,0,"a2",-1,"reload:.45"],["sniper-reload30",1,0,"r1",-1,"reload:.3"],["sniper-reload60",1,0,"r1",-1,"reload:.6"],["lmg-reload45",2,0,"h1",-1,"reload:.45"],
		["shotgun-reload20",3,0,"e1",-1,"reload:.2"],["shotgun-reload85",3,0,"e1",-1,"reload:.85"],["pistol-reload20",0,1,"pistol",-1,"reload:.2"],["pistol-reload70",0,1,"pistol",-1,"reload:.7"],
		["fold-hip",3,0,"e3",-1,""],["tidal-hip",3,0,"e2",-1,""],["mender-hip",5,0,"m3",-1,""],
		["rifle-reload10",0,0,"a1",-1,"reload:.1"],["rifle-reload35",0,0,"a1",-1,"reload:.35"],["rifle-reload62",0,0,"a1",-1,"reload:.62"],
		["revolver-reload30",1,1,"heavy_pistol",-1,"reload:.3"],["revolver-reload65",1,1,"heavy_pistol",-1,"reload:.65"],["rivet-reload65",3,1,"eng_pistol",-1,"reload:.65"],
		["tidal-reload45",3,0,"e2",-1,"reload:.45"],["tidal-reload66",3,0,"e2",-1,"reload:.66"],["fold-reload45",3,0,"e3",-1,"reload:.45"],["fold-reload65",3,0,"e3",-1,"reload:.65"],
		["shotgun-reload45",3,0,"e1",-1,"reload:.45"],["shotgun-reload70",3,0,"e1",-1,"reload:.7"],["mender-reload70",5,0,"m3",-1,"reload:.7"],
		["duet-reload25",0,1,"dual_pistols",-1,"reload:.25"],["duet-reload75",0,1,"dual_pistols",-1,"reload:.75"],["sniper2-hip",1,0,"r1",-1,""],["atlas-hip",0,0,"a3",-1,""],
		# 1.4.4: overhand throw phases and melee swing phases (knife, wrench).
		["throw15",0,2,"",1,"throw:.15"],["throw35",0,2,"",1,"throw:.35"],["throw60",0,2,"",1,"throw:.6"],["throw85",0,2,"",1,"throw:.85"],
		["throw05",0,2,"",1,"throw:.05"],["throw26",0,2,"",1,"throw:.26"],["throw45",0,2,"",1,"throw:.45"],["throw70",0,2,"",1,"throw:.7"],["throw95",0,2,"",1,"throw:.95"],["smoke-cook",4,2,"",0,"cook"],
		["knife-rest",0,MeleeCombat.SLOT,"",-1,"melee:-1"],["knife-wind",0,MeleeCombat.SLOT,"",-1,"melee:.03"],["knife-cut",0,MeleeCombat.SLOT,"",-1,"melee:.1"],["knife-through",0,MeleeCombat.SLOT,"",-1,"melee:.3"],
		["wrench-rest",3,MeleeCombat.SLOT,"",-1,"melee:-1"],["wrench-cut",3,MeleeCombat.SLOT,"",-1,"melee:.1"],["pistol-reload15",0,1,"pistol",-1,"reload:.15"],["laser-reload30",2,0,"h6",-1,"reload:.3"],
		# Round 8: the revolver reload as a sequence.
		["revolver-reload10",1,1,"heavy_pistol",-1,"reload:.1"],["revolver-reload20",1,1,"heavy_pistol",-1,"reload:.2"],["revolver-reload40",1,1,"heavy_pistol",-1,"reload:.4"],["revolver-reload50",1,1,"heavy_pistol",-1,"reload:.5"],
		["revolver-reload75",1,1,"heavy_pistol",-1,"reload:.75"],["quad-reload15",2,0,"h5",-1,"reload:.15"],["quad-reload45",2,0,"h5",-1,"reload:.45"],["quad-reload75",2,0,"h5",-1,"reload:.75"],["quad-reload90",2,0,"h5",-1,"reload:.9"],["pistol-reload30",0,1,"pistol",-1,"reload:.3"],["pistol-reload60",0,1,"pistol",-1,"reload:.6"],["revolver-reload85",1,1,"heavy_pistol",-1,"reload:.85"],["revolver-reload95",1,1,"heavy_pistol",-1,"reload:.95"]]
	# 1.4.5 "gearaudit": every held gadget / tool / melee item: how deep each
	# hand's points sink into it (AUDIT lines) plus a close-up of both hands.
	if "gearaudit" in only:
		var gear=[["grenade",0,2,"",1],["smoke",4,2,"",0],["flash",4,2,"",1],["medkit",5,2,"",0],["plate",0,2,"",0],["tablet",1,2,"",0],["cover",3,2,"",0],["marker",1,2,"",1],["tether",3,0,"remote",-1],["fix",3,1,"repair",-1],["link",5,0,"m1",-1]]
		for c in gear:
			equip(a,p,c[1],c[2],c[3],c[4]);aim.call(false);await settle([a])
			var item=null
			if is_instance_valid(a.view_body.held):item=a.view_body.held
			elif is_instance_valid(a.view_item):item=a.view_item
			if is_instance_valid(item):audit(a.view_body,item,"gear-"+c[0])
			else:print("AUDIT gear-",c[0]," (no held item)")
			await shot("fp-gear-"+c[0]);await closeups(a,"fp-gear-"+c[0])
		reset(p);p.role=3;p.placing="turret";await settle([a])
		var placing=null
		if is_instance_valid(a.view_body.held):placing=a.view_body.held
		elif is_instance_valid(a.view_item):placing=a.view_item
		if is_instance_valid(placing):audit(a.view_body,placing,"gear-turret")
		await shot("fp-gear-turret");await closeups(a,"fp-gear-turret");reset(p)
		for c in [["knife",0],["wrench",3]]:
			reset(p);p.role=c[1];p.slot=MeleeCombat.SLOT;a.shown_weapon="";await settle([a])
			if is_instance_valid(a.melee_view):audit(a.view_body,a.melee_view,"gear-"+c[0])
			await shot("fp-gear-"+c[0]);await closeups(a,"fp-gear-"+c[0])
		print("HANDS_REVIEW_OK");quit();return
	# 1.4.5 "triggerfit": per gun base, search the firing handle's offset (up /
	# forward, base metres) so the index fingertip is on the trigger and the
	# middle finger stays below the trigger guard's bar (GUARD_DROP under the
	# trigger). Prints the best offset per base.
	if "triggerfit" in only:
		var reps={"AK":"a1","SMG":"c1","Pistol":"pistol","Revolver":"heavy_pistol","Revolver_Small":"eng_pistol","Shotgun":"e1","ShortCannon":"e3","Sniper":"r2","Sniper_2":"r1"}
		for base_name in reps:
			var wid=reps[base_name];var w=Catalog.get_weapon(wid)
			equip(a,p,maxi(0,int(w.get("role",0))),1 if int(w.get("slot",0))==1 else 0,wid);aim.call(false);await settle([a])
			var gm:GunModel=a.view_weapon;var hd:Dictionary=GunModel.handles(base_name)
			var start:Vector3=gm.right_grip.position;var best=[INF]
			var shapes:Dictionary=gm.get_meta("grip_shapes",{})
			for dy in [-.03,-.02,-.01,0.,.01,.02,.03]:
				for dz in [-.02,-.01,0.,.01,.02,.03]:
					gm.right_grip.position=start+Vector3(0,dy,dz)
					# the solver's trigger is kept in the handle's frame (GunModel.place_handles)
					if shapes.has("R") and hd.has("trigger"):shapes.R.trigger=gm.right_grip.transform.affine_inverse()*Vector3(hd.trigger);gm.set_meta("grip_shapes",shapes)
					HeroIK.offset_cache.clear();HeroIK.grip_cache.clear();a.view_body.finger_memory.clear()
					await settle([a],8)
					var f=finger_fit(a.view_body,gm,hd)
					var cost=float(f[0])+12.*maxf(0.,float(f[1]))
					if cost<best[0]:best=[cost,dy,dz,f]
			gm.right_grip.position=start
			if shapes.has("R") and hd.has("trigger"):shapes.R.trigger=gm.right_grip.transform.affine_inverse()*Vector3(hd.trigger);gm.set_meta("grip_shapes",shapes)
			print("TRIGGERFIT %s (%s) best dy=%.3f dz=%.3f tip-trigger=%.3f middle_over_bar=%.3f"%[base_name,wid,best[1],best[2],best[3][0],best[3][1]])
		print("HANDS_REVIEW_OK");quit();return
	# "allguns": every weapon and tool in first person at the hip (right-handed).
	if "allguns" in only:
		var chosen=only.filter(func(x):return Catalog.weapons.has(x))
		for wid in Catalog.weapons:
			if not chosen.is_empty() and not wid in chosen:continue
			var w=Catalog.get_weapon(wid)
			var slot=1 if int(w.get("slot",0))==1 else 0
			var role=maxi(0,int(w.get("role",0)))
			equip(a,p,role,slot,wid);aim.call(false);await settle([a])
			if "audit" in only:audit(a.view_body,a.view_weapon,"fp "+str(wid))
			else:await shot("fp-gun-"+str(wid))
			var cut=[]
			for sd in ["L","R"]:
				if HeroIK.on_screen(a.camera,a.view_body.bone_world(a.view_body.bone["UpperArm."+sd]).origin):cut.append(sd)
			print("ELBOWS fp-gun-",wid," on_screen=",cut)
			if "armprofile" in only:print("ARMPROFILE fp-gun-",wid," ",posed_profile(a.view_body,"R")," | ",posed_profile(a.view_body,"L"))
			if "trigger" in only:trigger_report(a.view_body,"fp-gun-"+str(wid))
			if "fingerdebug" in only:
				HeroIK.debug_contact=true;HeroIK.grip_cache.clear();HeroIK.offset_cache.clear();await settle([a],1);HeroIK.debug_contact=false
			if "fpside" in only:await side_shot(a,"fp-side-"+str(wid))
		for c in [["knife",0,MeleeCombat.SLOT,""],["wrench",3,MeleeCombat.SLOT,""]]:
			reset(p);p.role=c[1];p.slot=c[2];a.shown_weapon="";await settle([a]);await shot("fp-gun-"+c[0])
		for c in [["grenade",0,1],["smoke",4,0],["medkit",5,0],["plate",0,0],["tablet",1,0],["cover",3,0],["defuse",0,9]]:
			equip(a,p,c[1],2,"",c[2]);await settle([a]);await shot("fp-gear-"+c[0])
		reset(p);p.role=3;p.placing="turret";await settle([a]);await shot("fp-gear-turret");reset(p)
		print("HANDS_REVIEW_OK");quit();return
	for hand in [1,-1]:
		p.hand=hand;a.handedness=hand
		for c in cases:
			var label=("fp-" if hand>0 else "fp-left-")+c[0]
			if not wanted(label):continue
			if hand<0 and not c[0] in ["rifle-hip","comet-reload45","tether","grenade-cook","pistol-hip","medkit","link","laser-hip","shotgun-hip","knife-cut","throw60","sniper-hip","quad-reload30","fold-hip","tidal-hip","mender-hip","revolver-reload50","shotgun-reload70","dual-hip"]:continue
			equip(a,p,c[1],c[2],c[3],c[4]);aim.call(false);await settle([a])
			if "ikdebug" in only and is_instance_valid(a.view_body):a.view_body.set_meta("ik_debug",true);await settle([a],1);a.view_body.remove_meta("ik_debug")
			var extra:String=c[5]
			if extra=="aim":aim.call(true);await settle([a])
			elif extra.begins_with("reload:"):reload_at(p,c[3],float(extra.split(":")[1]));await settle([a],14)
			elif extra=="cook":p.cooking=1;p.grenade_started=g.clock-.4;await settle([a])
			elif extra.begins_with("throw:"):
				# Mid-throw: throw_until - now = (1 - phase) * .28
				# (from the cooked hold, as in play: the throw path starts there)
				var phase=float(extra.split(":")[1])
				p.cooking=1;p.grenade_started=g.clock-.4;await settle([a])
				# ...then the throw is played through from its start to the phase, as
				# in play (the hand's hold on the grenade is taken at the first frame).
				p.cooking=0;p.throw_until=g.clock+Actor.THROW_TIME
				var start=g.clock
				while g.clock<start+phase*Actor.THROW_TIME-.0001:
					g.clock=minf(g.clock+1./60.,start+phase*Actor.THROW_TIME);a.visual(1./60.,p,g.clock);await process_frame
				g.clock=start # the clock is shared with the other cases; the pose keeps
			elif extra.begins_with("melee:"):
				p.melee_started=g.clock-float(extra.split(":")[1]);await settle([a],3)
			elif extra=="beam":
				for k in range(4):g.effect("laser",a.muzzle_world(),a.eye()-a.camera.global_basis.z*25.,1);await settle([a],2)
			elif extra=="heal":
				# An ally a little ahead and to the right, linked for a moment.
				if not g.players.has(60):g.add_player(60,"ALLY","hands_ally");g.spawn(60)
				var q=g.players[60];q.team=0;q.alive=true;q.protect=0.
				var b=g.actors[60];b.set_team(0);b.position=a.position+Vector3(2.4,0,-6.);b.aim_yaw=0.;b.rotation.y=0.;b.velocity=Vector3.ZERO
				for k in range(12):g.effect("heal",a.muzzle_world(),b.eye(),1,-100.,{"target":60});await settle([a,b],2)
			await shot(label)
			# First-person arms end at the hidden shoulder: that end on screen shows as a cut arm.
			if is_instance_valid(a.view_body) and a.view_body.visible:
				var cut=[]
				for sd in ["L","R"]:
					if HeroIK.on_screen(a.camera,a.view_body.bone_world(a.view_body.bone["UpperArm."+sd]).origin):cut.append(sd)
				print("ELBOWS ",label," on_screen=",cut," ",arm_metrics(a.view_body))
				if "thumbspot" in only:
					# screen points (fraction of the view) of each thumb's base and tip
					var vb2=a.view_body;var line="THUMBSPOT "+label;var size=a.camera.get_viewport().get_visible_rect().size
					for sd in ["L","R"]:
						var ch:Dictionary=HeroIK.finger_chains(vb2,sd)
						if not ch.has("Thumb"):continue
						var tb:Array=ch.Thumb;var base:Vector3=vb2.bone_world(tb[0]).origin;var tipx:Transform3D=vb2.bone_world(tb[-1])
						var tip:Vector3=tipx*Vector3(0,HeroIK.TIP.Thumb,0)
						var pb=a.camera.unproject_position(base)/size;var pt=a.camera.unproject_position(tip)/size
						line+=" %s base=(%.3f,%.3f) tip=(%.3f,%.3f) flex="%[sd,pb.x,pb.y,pt.x,pt.y]
						for b in tb:
							var q:Quaternion=(vb2.skeleton.get_bone_rest(b).basis.get_rotation_quaternion().inverse()*vb2.skeleton.get_bone_pose_rotation(b)).normalized()
							line+="%.2f/%s "%[-2.*atan2(q.x,q.w),str(Vector3(q.x,q.y,q.z).snapped(Vector3.ONE*.01))]
						line+=" style=%s"%str(vb2.get_meta("grip_style_"+sd,"?"))
						# the gap between thumb tip and index finger, against the load round (gun space)
						if is_instance_valid(a.view_weapon) and is_instance_valid(a.view_weapon.load_round) and a.view_weapon.load_round.visible and ch.has("Index"):
							var gap:Vector3=(tip+vb2.bone_world(ch.Index[2]).origin)*.5
							var to_gun:Transform3D=a.view_weapon.global_transform.affine_inverse()
							line+=" gap-round(gun)=%s"%str((to_gun*gap-to_gun*a.view_weapon.load_round.global_position).snapped(Vector3.ONE*.001))
					print(line)
			# Highest screen point of the view weapon (fraction of the height from the top).
			if is_instance_valid(a.view_weapon) and a.view_weapon.visible:
				var top=1.;var size=a.camera.get_viewport().get_visible_rect().size
				for m in a.view_weapon.find_children("*","MeshInstance3D",true,false):
					if not m.is_visible_in_tree() or m.mesh==null:continue
					var box:AABB=m.mesh.get_aabb();var xf:Transform3D=m.global_transform
					for i in range(8):
						var pt:Vector3=xf*box.get_endpoint(i)
						if a.camera.is_position_behind(pt):continue
						top=minf(top,a.camera.unproject_position(pt).y/size.y)
				print("GUNTOP ",label," top=%.2f"%top)
			if "closeup" in only and is_instance_valid(a.view_body) and a.view_body.visible:await closeups(a,label)
			if "audit" in only and is_instance_valid(a.view_body) and is_instance_valid(a.view_body.held):audit(a.view_body,a.view_body.held,label)
			if "debug" in only and is_instance_valid(a.melee_view) and a.melee_view.visible:
				var cb:Basis=a.camera.global_basis.inverse();var vb=a.view_body
				var wx:Vector3=vb.bone_world(vb.bone["Wrist.R"]).basis.x.normalized()
				print("BLADE ",label," blade_cam=",(cb*a.melee_view.pivot.global_basis.y.normalized()).snapped(Vector3.ONE*.01)," edge_cam=",(cb*(-a.melee_view.pivot.global_basis.x).normalized()).snapped(Vector3.ONE*.01)," wrist_x_cam=",(cb*wx).snapped(Vector3.ONE*.01)," pivot_rot=",a.melee_view.pivot.rotation," parent=",a.melee_view.get_parent().name," parent_bone=",a.melee_view.get_parent().bone_name if a.melee_view.get_parent() is BoneAttachment3D else "-")
			if "debug" in only and is_instance_valid(a.view_body):
				var vb=a.view_body;var line="JOINTS "+label+" vis=%s tree=%s arms=%s held=%s item=%s gun=%s ovr=%s"%[str(vb.visible),str(vb.is_visible_in_tree()),str(vb.skeleton.get_node("FPArms").is_visible_in_tree()),str(vb.held),str(a.item_model.visible),str(a.gun.position.snapped(Vector3.ONE*.01)),str(a.camera.to_local(vb.wrist_override.R.origin).snapped(Vector3.ONE*.01)) if vb.wrist_override.has("R") else "-"]
				for n in ["UpperArm.L","LowerArm.L","Wrist.L","UpperArm.R","LowerArm.R","Wrist.R"]:
					line+=" %s=%s"%[n,str(a.camera.to_local(vb.bone_world(vb.bone[n]).origin).snapped(Vector3.ONE*.01))]
				print(line)
			aim.call(false);reset(p);p.mag[c[3]]=int(Catalog.get_weapon(c[3]).get("mag",1)) if c[3]!="" else 0
	# Third person: a lineup holding the same things, seen from the front and side.
	p.hand=1;a.handedness=1
	var lineup=[[0,0,"a1",-1,"",1],[3,0,"e1",-1,"",1],[1,0,"r1",-1,"",1],[0,1,"pistol",-1,"",1],[4,1,"dual_pistols",-1,"",1],
		[2,0,"h4",-1,"",1],[2,0,"h4",-1,"reload:.45",1],[3,0,"remote",-1,"",1],[5,2,"",0,"",1],[0,2,"",1,"cook",1],[0,0,"a1",-1,"",-1],[2,0,"h4",-1,"reload:.45",-1],[5,0,"m1",-1,"",1],[5,0,"m1",-1,"",-1]]
	var group=[]
	for i in range(lineup.size()):
		var id=-(i+1);g.add_player(id,"BOT%d"%i,"hands_bot%d"%i);g.spawn(id)
		var e=lineup[i];var q=g.players[id];q.role=e[0];q.slot=e[1];q.team=0;q.protect=0.;q.alive=true;q.hand=e[5]
		if e[1]==0:q.primary=e[2]
		elif e[1]==1:q.secondary=e[2]
		if e[3]>=0:q.gadget=e[3];q.gadget_count=3;q.owned_gadget=true
		# Two rows of six on the open ground of objective A.
		var site:Vector3=Vector3(0,0,24)
		var b=g.actors[id];b.set_team(0);b.handedness=e[5];b.position=site+Vector3(-3.+(i%6)*1.2,.05,-1.5-(i/6)*4.5);b.aim_yaw=PI;b.rotation.y=PI;group.append(b)
		if str(e[4]).begins_with("reload:"):reload_at(q,e[2],float(str(e[4]).split(":")[1]))
		elif e[4]=="cook":q.cooking=1;q.grenade_started=g.clock-.4
	a.set_local(false);a.visible=false
	if g.actors.has(60):g.actors[60].position=Vector3(40,.1,-40)
	var camera=Camera3D.new();root.add_child(camera);camera.current=true;camera.fov=38
	# Stand them on the floor (grounded pose, not the falling one).
	for k in range(6):
		for b in group:b.velocity=Vector3(0,-2,0);b.move_and_slide()
		await physics_frame
	await settle(group,30)
	# Arms inside the torso (third person): deepest arm sample per hero.
	for i in range(group.size()):
		var h:HeroCharacter=group[i].character;var t=HeroIK.torso_frame(h);var worst=0.;var where=""
		for side in ["L","R"]:
			var s=h.bone_world(h.bone["UpperArm."+side]).origin;var e=h.bone_world(h.bone["LowerArm."+side]).origin;var w=h.bone_world(h.bone["Wrist."+side]).origin
			for k in range(9):
				var depth=HeroIK.torso_depth(t,s.lerp(e,k/8.)) if k>=3 else 0. # the shoulder end belongs to the torso
				if depth>worst:worst=depth;where=side+" upper"
				depth=HeroIK.torso_depth(t,e.lerp(w,k/8.))
				if depth>worst:worst=depth;where=side+" fore"
		print("TORSO bot%d %s depth=%.2f %s"%[i,str(lineup[i].slice(0,5)),worst,where])
		# How far each wrist ended up from the marker it should hold.
		if is_instance_valid(h.held):
			var fb=h.facing_basis().orthonormalized();var rel=h.held.global_position-h.bone_world(h.skeleton.find_bone("Chest")).origin
			var line="   HANDS bot%d held=%s two=%s item_local=(%.2f,%.2f,%.2f)"%[i,h.held.name,str(h.state.get("two_hands","")),rel.dot(fb.x),rel.dot(fb.y),rel.dot(fb.z)]
			for side in ["R","L"]:
				var marker=h.held.get_node_or_null("RightGrip" if side=="R" else "LeftGrip")
				if marker:line+=" %s=%.3f"%[side,h.bone_world(h.bone["Wrist."+side]).origin.distance_to(marker.global_position)]
			var pay=h.held.find_child("Payload",true,false)
			line+=" visible=%s payload=%s"%[str(h.held.is_visible_in_tree()),str(pay.is_visible_in_tree()) if pay else "none"]
			if pay:
				var pr=pay.global_position-h.bone_world(h.bone["Wrist.R"]).origin
				line+=" payload_from_wristR=%.3f"%pr.length()
			print(line)
		if worst>.05:
			var f=h.facing_basis().orthonormalized();var c=h.bone_world(h.skeleton.find_bone("Chest")).origin
			for n in ["UpperArm.R","LowerArm.R","Wrist.R","UpperArm.L","LowerArm.L","Wrist.L"]:
				var q=h.bone_world(h.bone[n]).origin-c
				print("   %s local=(%.2f,%.2f,%.2f)"%[n,q.dot(f.x),q.dot(f.y),q.dot(f.z)])
			var gw=group[i].world_weapon
			if is_instance_valid(gw) and gw.launcher:
				var rear=gw.to_global(Vector3(0,gw.muzzle.position.y,float(gw.base.get_meta("rear",0.)))*gw.base.scale)-c
				print("   rear opening local=(%.2f,%.2f,%.2f)"%[rear.dot(f.x),rear.dot(f.y),rear.dot(f.z)])
	# Close-ups of the held gear and the rocket reload (front-right, then left side).
	for i in [3,4,6,7,8,9,12,13]:
		if not wanted("tp-close-%d"%i):continue
		var b=group[i];var f=b.character.facing_basis().orthonormalized();var focus=b.global_position+Vector3.UP*1.2
		camera.position=focus-f.z*1.6+f.x*.7+Vector3.UP*.15;camera.look_at(focus);await shot("tp-close-%d"%i)
		camera.position=focus-f.z*.5-f.x*1.5+Vector3.UP*.1;camera.look_at(focus);await shot("tp-close-%d-side"%i)
		# 1.4.4: the hands themselves, from the front-right and the front-left, half a metre away.
		if is_instance_valid(b.world_weapon) and b.world_weapon.visible:
			var hands:Vector3=b.world_weapon.global_transform*(b.world_weapon.right_grip.position*b.world_weapon.base.scale)
			camera.fov=30.
			camera.position=hands-f.z*.45+f.x*.35+Vector3.UP*.12;camera.look_at(hands);await shot("tp-hands-%d"%i)
			camera.position=hands-f.z*.45-f.x*.35+Vector3.UP*.12;camera.look_at(hands);await shot("tp-hands-%d-left"%i)
			camera.position=hands+f.x*.55+Vector3.UP*.05;camera.look_at(hands);await shot("tp-hands-%d-right"%i)
			camera.fov=38.
	# LINK beam from the side: the medic (bot12) heals bot13 standing 6 m ahead.
	if wanted("tp-heal"):
		var healer=group[12];var ally=group[13]
		ally.position=healer.position+Vector3(1.6,0,6.);ally.aim_yaw=0.;ally.rotation.y=0.
		var to=ally.position-healer.position;healer.aim_yaw=atan2(-to.x,-to.z);healer.rotation.y=healer.aim_yaw;healer.input_state.yaw=healer.aim_yaw
		await settle([healer,ally],12)
		for k in range(14):g.effect("heal",healer.muzzle_world(),ally.eye(),healer.pid,-100.,{"target":ally.pid});await settle([healer,ally],2)
		var mid=healer.position.lerp(ally.position,.5)+Vector3.UP*1.2
		var relink=func():
			for k in range(6):g.effect("heal",healer.muzzle_world(),ally.eye(),healer.pid,-100.,{"target":ally.pid});await settle([healer,ally],2)
		camera.position=mid+Vector3(7.5,.8,-1.2);camera.look_at(mid);await shot("tp-heal-side")
		await relink.call()
		camera.position=healer.position+Vector3(-.9,1.75,-1.6);camera.look_at(ally.position+Vector3.UP*1.1);await shot("tp-heal-behind")
		await relink.call()
		camera.position=ally.position+Vector3(-1.2,1.5,1.8);camera.look_at(ally.position+Vector3.UP*1.1);await shot("tp-heal-target")
	for half in [0,1]:
		var centre=Vector3(0.,group[half*6].position.y+1.15,group[half*6].position.z)
		if wanted("tp-front-%d"%half):
			camera.position=centre+Vector3(0,.35,3.4);camera.look_at(centre);await shot("tp-front-%d"%half)
		if wanted("tp-side-%d"%half):
			camera.position=centre+Vector3(3.6,.4,1.6);camera.look_at(centre);await shot("tp-side-%d"%half)
		if wanted("tp-back-%d"%half):
			camera.position=centre+Vector3(-1.2,.5,-3.2);camera.look_at(centre);await shot("tp-back-%d"%half)
	print("HANDS_REVIEW_OK");quit()
