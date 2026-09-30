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
func settle(actors:Array,frames:int=24):
	for i in range(frames):
		for a in actors:a.visual(1./30.,g.players[a.pid],g.clock)
		await process_frame
func reset(p:Dictionary):
	p.slot=0;p.cooking=0;p.erase("grenade_started");p.placing="";p.erase("melee_started");p.gadget_count=3;p.owned_gadget=true;p.reload=0.
func equip(a,p:Dictionary,role:int,slot:int,item:String,gadget:int=-1):
	reset(p);p.role=role;p.slot=slot
	if slot==0:p.primary=item
	elif slot==1:p.secondary=item
	if gadget>=0:p.gadget=gadget
	a.shown_weapon="";a.set_team(0)
func reload_at(p:Dictionary,wid:String,phase:float):
	var w=Catalog.get_weapon(wid);p.reload_tactical=false;p.reload_weapon=wid;p.mag[wid]=0
	p.reload=g.clock+float(w.reload)*(1.-phase);p.reload_started=g.clock-float(w.reload)*phase
func run():
	for arg in OS.get_cmdline_user_args():only.append(arg)
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
		["tether",3,0,"remote",-1,""],["fix",3,1,"repair",-1,""],["link",5,0,"m1",-1,""]]
	for hand in [1,-1]:
		p.hand=hand;a.handedness=hand
		for c in cases:
			var label=("fp-" if hand>0 else "fp-left-")+c[0]
			if not wanted(label):continue
			if hand<0 and not c[0] in ["rifle-hip","comet-reload45","tether","grenade-cook","pistol-hip","medkit"]:continue
			equip(a,p,c[1],c[2],c[3],c[4]);aim.call(false);await settle([a])
			var extra:String=c[5]
			if extra=="aim":aim.call(true);await settle([a])
			elif extra.begins_with("reload:"):reload_at(p,c[3],float(extra.split(":")[1]));await settle([a],6)
			elif extra=="cook":p.cooking=1;p.grenade_started=g.clock-.4;await settle([a])
			await shot(label)
			if "debug" in only and is_instance_valid(a.view_body):
				var vb=a.view_body;var line="JOINTS "+label
				for n in ["UpperArm.L","LowerArm.L","Wrist.L","UpperArm.R","LowerArm.R","Wrist.R"]:
					line+=" %s=%s"%[n,str(a.camera.to_local(vb.bone_world(vb.bone[n]).origin).snapped(Vector3.ONE*.01))]
				print(line)
			aim.call(false);reset(p);p.mag[c[3]]=int(Catalog.get_weapon(c[3]).get("mag",1)) if c[3]!="" else 0
	# Third person: a lineup holding the same things, seen from the front and side.
	p.hand=1;a.handedness=1
	var lineup=[[0,0,"a1",-1,"",1],[3,0,"e1",-1,"",1],[1,0,"r1",-1,"",1],[0,1,"pistol",-1,"",1],[4,1,"dual_pistols",-1,"",1],
		[2,0,"h4",-1,"",1],[2,0,"h4",-1,"reload:.45",1],[3,0,"remote",-1,"",1],[5,2,"",0,"",1],[0,2,"",1,"cook",1],[0,0,"a1",-1,"",-1],[2,0,"h4",-1,"reload:.45",-1]]
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
	for i in [6,7,8,9]:
		if not wanted("tp-close-%d"%i):continue
		var b=group[i];var f=b.character.facing_basis().orthonormalized();var focus=b.global_position+Vector3.UP*1.2
		camera.position=focus-f.z*1.6+f.x*.7+Vector3.UP*.15;camera.look_at(focus);await shot("tp-close-%d"%i)
		camera.position=focus-f.z*.5-f.x*1.5+Vector3.UP*.1;camera.look_at(focus);await shot("tp-close-%d-side"%i)
	for half in [0,1]:
		var centre=Vector3(0.,group[half*6].position.y+1.15,group[half*6].position.z)
		if wanted("tp-front-%d"%half):
			camera.position=centre+Vector3(0,.35,3.4);camera.look_at(centre);await shot("tp-front-%d"%half)
		if wanted("tp-side-%d"%half):
			camera.position=centre+Vector3(3.6,.4,1.6);camera.look_at(centre);await shot("tp-side-%d"%half)
		if wanted("tp-back-%d"%half):
			camera.position=centre+Vector3(-1.2,.5,-3.2);camera.look_at(centre);await shot("tp-back-%d"%half)
	print("HANDS_REVIEW_OK");quit()
