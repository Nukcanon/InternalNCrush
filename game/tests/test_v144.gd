extends SceneTree
# 1.4.4: first-person arms from fixed shoulders (thick, to the shoulder),
# firing hand below the trigger guard, rocket side C-grip, whole magazines
# with lids (pistols keep their grip), one-handed first-person pistols, melee
# tools in the fist, overhand throws, engineer placement rules, ammo HUD
# outlines and equal dialog buttons.
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func run():
	Catalog.load_all()
	# --- Magazines: whole pieces, a lid on top, pistols keep the grip -----------
	for base in ["AK","SMG","Sniper","Sniper_2"]:
		var raw:Node3D=GunModel.base_scene(base).instantiate();root.add_child(raw)
		var mag:MeshInstance3D=raw.get_node_or_null("Magazine");var body:MeshInstance3D=raw.get_node("Body")
		expect(mag!=null and mag.mesh!=null and mag.mesh.get_surface_count()>=2,"%s: magazine baked as its own mesh with a lid surface"%base)
		if mag and mag.mesh:
			var mb:AABB=mag.mesh.get_aabb();var bb:AABB=body.mesh.get_aabb()
			expect(mb.size.y>.08 and mb.end.y<=bb.end.y-.02,"%s: the whole magazine (%.2f m tall) hangs under the receiver"%[base,mb.size.y])
			# No magazine sliver on the body: no body vertex lies inside the
			# magazine's lower part (below its lid) and within its footprint.
			var slivers=0
			for s in range(body.mesh.get_surface_count()):
				for v in body.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
					if v.y<mb.end.y-.07 and v.y>mb.position.y+.01 and absf(v.x-mb.get_center().x)<mb.size.x*.4 and v.z>mb.position.z+mb.size.z*.25 and v.z<mb.end.z-mb.size.z*.25:slivers+=1
			expect(slivers==0,"%s: nothing of the magazine stays on the body (%d vertices)"%[base,slivers])
		raw.free()
	var pistol:Node3D=GunModel.base_scene("Pistol").instantiate();root.add_child(pistol)
	var pmag:MeshInstance3D=pistol.get_node_or_null("Magazine");var pbody:MeshInstance3D=pistol.get_node("Body")
	expect(pmag!=null and pmag.mesh!=null and pmag.mesh.get_surface_count()==2,"pistol: floor plate plus a magazine body")
	if pmag and pmag.mesh:
		var grip_verts=0;var bb:AABB=pbody.mesh.get_aabb()
		for s in range(pbody.mesh.get_surface_count()):
			for v in pbody.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				if v.y<bb.position.y+.04:grip_verts+=1
		expect(grip_verts>40,"pistol: the grip stays on the body when the magazine leaves (%d low vertices)"%grip_verts)
		var mb:AABB=pmag.mesh.get_aabb()
		expect(mb.size.y>.05 and mb.size.x<.03,"pistol: the magazine body fits inside the grip %s"%str(mb.size))
	pistol.free()
	# The laser rifle's cells replace the magazine box entirely.
	var arc=GunModel.new();arc.build(Catalog.get_weapon("h6"),false);root.add_child(arc)
	var shown=0
	for m in arc.magazine.find_children("*","MeshInstance3D",true,false):
		if m.visible and m.mesh and not str(m.get_parent().name)=="Cells":shown+=1
	expect(arc.magazine is MeshInstance3D and arc.magazine.mesh==null and shown==0 and arc.magazine.has_node("Cells"),"ARC: only the two cells remain of the magazine")
	arc.free()
	# --- Rocket side C-grip ----------------------------------------------------
	var loader=GunModel.new();loader.build(Catalog.get_weapon("h5"),false);root.add_child(loader)
	var load_hand=ReloadMotion.support(loader,{"reload":.45,"rounds":0})
	expect(str(load_hand.get("style",""))=="cradle","QUAD loading hand uses the side C grip")
	loader.free()
	var left:Basis=HeroIK.FRAMES.cradle.L;var right:Basis=HeroIK.FRAMES.cradle.R
	expect(-left.z.x>.9 and left.y.y>.9 and left.x.z>.9,"cradle L: palm to the rocket, knuckles up, thumb back along the near side")
	expect(-right.z.x<-.9 and right.y.y>.9 and right.x.z<-.9,"cradle R: the mirror image (palm the other way, thumb -X back)")
	expect(is_equal_approx(left.determinant(),1.) and is_equal_approx(right.determinant(),1.),"cradle frames are right-handed")
	# --- First-person arms: fixed shoulders behind the eye, thick, to the shoulder
	for hold in ["rifle","pistol","item"]:
		var s=Actor.fp_shoulders(hold,1.)
		expect(s.R.x>.15 and s.L.x<-.15 and s.R.y<-.2 and s.L.y<-.2 and s.R.z>0.,"fp shoulders %s: apart, below and behind the eye"%hold)
		var m=Actor.fp_shoulders(hold,-1.)
		expect(is_equal_approx(m.R.x,-s.R.x) and is_equal_approx(m.L.x,-s.L.x),"fp shoulders %s mirror for left-handed players"%hold)
	expect(Actor.VIEW_BODY_SCALE*.39>.6,"first-person arm reach about a person's (%.2f m)"%(Actor.VIEW_BODY_SCALE*.39))
	for role in [0,1,5]:
		var hero=HeroCharacter.new();root.add_child(hero);hero.build(role,0,false);hero.first_person_only()
		var arms:MeshInstance3D=hero.skeleton.get_node_or_null("FPArms")
		expect(arms!=null and arms.visible and arms.mesh!=null,"hero %d: first-person arm mesh"%role)
		if arms and arms.mesh:
			# Shoulder-driven vertices are part of the arm mesh (the arm reaches the shoulder).
			var skin:Skin=arms.skin;var shoulder_binds={};var fore_binds={}
			for bind in range(skin.get_bind_count()):
				var name=skin.get_bind_name(bind)
				if name=="":name=hero.skeleton.get_bone_name(skin.get_bind_bone(bind))
				if name.begins_with("Shoulder"):shoulder_binds[bind]=true
				if name=="LowerArm.R":fore_binds[bind]=[skin.get_bind_pose(bind).affine_inverse()]
			var shoulder_verts=0;var radii=[]
			for s in range(arms.mesh.get_surface_count()):
				var arrays=arms.mesh.surface_get_arrays(s);var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
				var per=bones.size()/maxi(1,verts.size())
				for i in range(verts.size()):
					var best=-1;var bw=-1.
					for k in range(per):
						if weights[i*per+k]>bw:bw=weights[i*per+k];best=bones[i*per+k]
					if shoulder_binds.has(best):shoulder_verts+=1
					if fore_binds.has(best) and bw>.8:
						var bone:Transform3D=fore_binds[best][0];var rel=verts[i]-bone.origin;var y=bone.basis.y.normalized()
						radii.append((rel-y*rel.dot(y)).length())
			expect(shoulder_verts>0,"hero %d: arm mesh reaches the shoulder (%d shoulder vertices)"%[role,shoulder_verts])
			var mean=0.
			for r in radii:mean+=r
			mean=mean/maxf(1.,radii.size())
			expect(mean>=HeroCharacter.FP_FOREARM_R*.9,"hero %d: forearm girth %.3f at the shared target %.3f"%[role,mean,HeroCharacter.FP_FOREARM_R])
		hero.queue_free()
	# The IK keeps a fixed anchor and only stretches it when the hand is out of reach.
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false);hero.first_person_only()
	var cam=Camera3D.new();root.add_child(cam);cam.global_position=Vector3(0,1.6,0)
	hero.set_meta("fp_camera",cam);hero.set_meta("fp_shoulders",Actor.fp_shoulders("rifle",1.))
	hero.global_basis=Basis.from_scale(Vector3.ONE*Actor.VIEW_BODY_SCALE);hero.global_position=Vector3(0,1.6,0)-Vector3(0,1.62,0)+Actor.VIEW_BODY_OFFSET
	var gun=GunModel.new();gun.build(Catalog.get_weapon("a1"),false);hero.hold(gun)
	gun.position=Vector3(.16,-.25,-.40)-gun.right_grip.position*gun.base.scale
	hero.frame_override=cam
	for i in range(6):hero.drive(1./30.,{"hold":"rifle","hands":1.,"two_hands":true})
	var anchor:Vector3=cam.global_transform*Actor.fp_shoulders("rifle",1.).R
	expect(hero.bone_world(hero.bone["UpperArm.R"]).origin.distance_to(anchor)<.02+float(hero.get_meta("fp_stretch_R",0.)),"first-person upper arm starts at its shoulder anchor")
	expect(float(hero.get_meta("fp_stretch_R",0.))<.01 and float(hero.get_meta("fp_stretch_L",0.))<.12,"rifle grips within reach of the fixed shoulders (stretch R %.2f L %.2f)"%[float(hero.get_meta("fp_stretch_R",0.)),float(hero.get_meta("fp_stretch_L",0.))])
	for side in ["R","L"]:
		var u=hero.bone_world(hero.bone["UpperArm."+side]).origin
		expect(not HeroIK.on_screen(cam,u),"shoulder %s stays off screen"%side)
	# Melee override: the fist follows the given wrist transform, straight along the arm.
	var wrist=cam.global_transform*Transform3D(Basis.IDENTITY,MeleeVisual.swing_wrist(-1.))
	var dir:Vector3=(MeleeVisual.swing_wrist(-1.)-Actor.fp_shoulders("item",1.).R).normalized()
	var x:Vector3=-(Vector3.UP-dir*dir.dot(Vector3.UP)).normalized()
	wrist.basis=cam.global_basis*Basis(x,dir,x.cross(dir).normalized())
	hero.wrist_override={"R":wrist};hero.hold(null)
	for i in range(6):hero.drive(1./30.,{"hold":"item","hands":1.,"two_hands":false})
	var w=hero.bone_world(hero.bone["Wrist.R"]);var fore=hero.bone_world(hero.bone["LowerArm.R"])
	expect(w.origin.distance_to(wrist.origin)<.02,"melee fist reaches the swing point (%.3f m)"%w.origin.distance_to(wrist.origin))
	expect((w.origin-fore.origin).normalized().angle_to(w.basis.y.normalized())<.35,"melee wrist stays nearly straight (%.0f deg)"%rad_to_deg((w.origin-fore.origin).normalized().angle_to(w.basis.y.normalized())))
	hero.wrist_override={};hero.queue_free();gun.queue_free();cam.queue_free()
	# Throw path: winds up above and behind the cooking hand, releases ahead and lower.
	var wind=Actor.throw_path(.3)[0];var release=Actor.throw_path(.8)[0];var cook=Actor.throw_path(0.)[0]
	expect(wind.y>cook.y+.2 and wind.z>cook.z+.08 and release.z<wind.z-.2 and release.y<wind.y-.1,"overhand throw: up and back, then forward and down")
	# --- First-person pistols in one hand, third person in two ---------------
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(3):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=false;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.add_player(1,"Eng","e");g.phase="combat";g.clock=100.
	var p=g.players[1];p.role=0;p.slot=1;p.secondary="pistol";p.alive=true;p.protect=0.
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.position=Vector3(0,.1,0);a.reset_view(0.)
	for i in range(3):a.visual(1./30.,p,g.clock)
	expect(is_instance_valid(a.view_body) and a.view_body.visible and a.view_body.state.get("two_hands",true)==false,"first-person pistol is held in one hand")
	expect(a.character.state.get("two_hands",false)==true,"third-person pistol is held in both hands")
	# Support cup covers the firing hand: wider and deeper than the grip alone.
	var side=GunModel.new();side.build(Catalog.get_weapon("pistol"),false);root.add_child(side)
	var shapes:Dictionary=side.get_meta("grip_shapes",{})
	expect(shapes.has("L") and bool(shapes.L.get("cup",false)) and shapes.L.half.x>shapes.R.half.x+.02 and shapes.L.half.z>shapes.R.half.z+.025,"pistol support cup encloses the firing hand's fingers")
	side.free()
	# --- Engineer placement ------------------------------------------------------
	p.role=3;p.slot=0
	expect(Deployment.floor_limit("cover")<.8 and Deployment.floor_limit("turret")>=.88,"cover may stand on slopes, turrets on level ground")
	var tilted=Deployment.basis_on_ground(null,Vector3.ZERO,0.,"cover")
	expect(tilted.y.is_equal_approx(Vector3.UP),"no ground: level basis")
	# Only the player's own footprint blocks a build.
	expect(Deployment.SELF_CLEARANCE<=.5 and Deployment.SELF_CLEARANCE>0.,"self clearance about half a metre")
	expect(int(g.options.mode)!=4,"test lobby is not bomb mode")
	g.arena.sites=[Vector3(0,0,-3.)];g.arena.ffa_spawns=[]
	expect(Deployment.layout_allows(g,Vector3(0,0,-3.)),"cover may stand near an objective outside bomb mode")
	g.options.mode=4
	expect(not Deployment.layout_allows(g,Vector3(0,0,-3.)),"bomb mode keeps the plant site clear")
	g.options.mode=0
	expect(not Deployment.allowed(g,a.position+Vector3(0,0,-.3),0.,"cover",1),"no build on the player")
	g.queue_free()
	# --- Ammo HUD: spent slots are outlines of the round's own shape --------
	var src=FileAccess.get_file_as_string("res://scripts/ammo_pips.gd")
	expect("empty outline of the same round" in src and src.count("draw_polyline")>=3,"spent rounds draw as shell / cartridge outlines")
	# --- Dialog buttons: no spacer between them ------------------------------
	var menu_font=FontVariation.new();menu_font.base_font=load("res://assets/fonts/DoHyeon-Regular.ttf");menu_font.fallbacks=[UiSkin.symbol_font(),load("res://assets/Korean.ttf")]
	var theme=UiSkin.build(menu_font,false)
	var dialog=ConfirmationDialog.new();root.add_child(dialog)
	dialog.dialog_text="x";dialog.ok_button_text="적용하고 나가기";dialog.cancel_button_text="계속 설정";dialog.add_button("적용하지 않고 나가기",false,"discard")
	DialogStyle.apply(dialog,theme);DialogStyle.popup(dialog)
	for i in range(4):await process_frame
	var row=dialog.get_ok_button().get_parent();var xs=[];var widths=[]
	for c in row.get_children(true):
		if c is Button and c.visible:xs.append(c.position.x);widths.append(c.size.x)
		elif c is Control:expect(not c.visible,"dialog spacer hidden")
	xs.sort()
	expect(xs.size()==3 and absf((xs[1]-xs[0])-(xs[2]-xs[1]))<1.5 and absf(widths[0]-widths[2])<1.5,"three dialog buttons at equal gaps (%s)"%str(xs))
	dialog.queue_free()
	print("V144_RESULT %d/%d"%[checks-failures,checks])
	quit(1 if failures>0 else 0)
