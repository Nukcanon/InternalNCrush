extends SceneTree
# 1.4.2: armour fitted per hero and tier (skinned, baked), carried gear on the
# body (stowed weapons, kit by count), corpses dressed like the living hero,
# and the bakes matching a fresh fit.
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func run():
	Catalog.load_all()
	# Fitted armour: one skinned mesh on the hero's own skin, per tier.
	var sizes={}
	for role in range(6):
		var hero=HeroCharacter.new();root.add_child(hero);hero.build(role,role%2,false)
		var body=FittedArmor.body_of(hero)
		for level in [1,2]:
			hero.set_armor(level)
			var armor:MeshInstance3D=hero.skeleton.get_node_or_null("FittedArmor")
			expect(armor!=null and armor.skin==body.skin and armor.mesh.get_surface_count()==1,"hero %d wears fitted armour tier %d on its own skin"%[role,level])
			if armor==null:continue
			var box:AABB=armor.get_aabb();var torso:AABB=body.get_aabb()
			for part in hero.meshes():
				if str(part.name).ends_with("_Legs"):torso=torso.merge(part.get_aabb())
			expect(box.size.y<.8 and box.size.x<.5 and torso.grow(.1).encloses(box),"hero %d tier %d armour stays on the torso %s in %s"%[role,level,box,torso])
			sizes[[role,level]]=armor.mesh.surface_get_array_index_len(0)
			# The team accents are recoloured per team (linear vertex colours).
			var colors:PackedColorArray=armor.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
			var team_linear:Color=HeroStyle.TEAM_MAIN[role%2].srgb_to_linear()
			expect(Array(colors).any(func(c):return Vector3(c.r-team_linear.r,c.g-team_linear.g,c.b-team_linear.b).length()<.02) and not Array(colors).any(func(c):return c.r>.95 and c.g<.05 and c.b>.95),"hero %d tier %d armour carries its team colour"%[role,level])
		expect(sizes[[role,2]]>sizes[[role,1]],"heavy armour has more parts than light (hero %d)"%role)
		hero.set_armor(0);await process_frame
		expect(hero.skeleton.get_node_or_null("FittedArmor")==null,"armour tier 0 removes the vest (hero %d)"%role)
		# The shipped bakes match a fresh fit of the current hero and design.
		for level in [1,2]:
			var baked:ArrayMesh=load(FittedArmor.baked_path(role,level));var fresh=FittedArmor.make_mesh(hero,body,level)
			expect(baked!=null and fresh!=null and baked.surface_get_array_index_len(0)==fresh.surface_get_array_index_len(0) and baked.get_aabb().position.distance_to(fresh.get_aabb().position)<.002 and baked.get_aabb().size.distance_to(fresh.get_aabb().size)<.002,"armour bake is current (hero %d tier %d)"%[role,level])
		var measured=CarriedGear.to_json(CarriedGear.measure(hero))
		var shipped=JSON.parse_string(FileAccess.get_file_as_string(CarriedGear.POINTS_PATH))[HeroCharacter.OUTFITS[role]]
		expect(str(measured.back)==str(shipped.back) and str(measured.thigh)==str(shipped.thigh) and measured.ring.size()==shipped.ring.size(),"carried-gear anchor bake is current (hero %d)"%role)
		hero.free()
	var kits:ArrayMesh=load(CarriedGear.KITS_PATH)
	expect(kits!=null and kits.get_surface_count()==CarriedGear.KIT_KINDS.size(),"every kit piece is baked")
	# Carried gear follows the loadout and the counts.
	var p={"role":0,"gadget":8,"gadget_count":2,"owned_gadget":true,"primary":"a1","secondary":"pistol","armor_max":50}
	var spec=CarriedGear.spec_for(p,"a1",false)
	expect(spec.primary_out and not spec.secondary_out and spec.kit==[["frag",2]] and spec.armor==2,"two frags on the belt, rifle in hand")
	expect(CarriedGear.spec_for(p,"",true).kit==[["frag",1]],"the grenade in hand leaves one on the belt")
	p.gadget_count=0;expect(CarriedGear.spec_for(p,"",false).kit.is_empty(),"no grenades left, none shown")
	expect(CarriedGear.spec_for({"role":4,"gadget":0,"gadget_count":3,"smoke":3,"owned_gadget":true,"primary":"","secondary":"pistol"},"",false).kit==[["smoke",3]],"support smoke count on the belt")
	expect(CarriedGear.spec_for({"role":5,"gadget":0,"gadget_count":1,"owned_gadget":true,"primary":"","secondary":"pistol"},"",false).kit==[["medkit",1]],"medic kit on the belt")
	expect(CarriedGear.spec_for({"role":2,"gadget":9,"gadget_count":1,"owned_gadget":true,"primary":"","secondary":"pistol"},"",false).kit==[["defuse",1]],"defuse kit on the belt")
	expect(CarriedGear.spec_for({"role":3,"gadget":1,"gadget_count":3,"owned_gadget":true,"primary":"","secondary":"pistol"},"",false).kit==[["covers1",3]],"engineer cover kits by tier")
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false);hero.set_armor(2)
	p.gadget_count=2
	CarriedGear.apply(hero,CarriedGear.spec_for(p,"pistol",false))
	var back:MeshInstance3D=hero.skeleton.get_node_or_null("StowBack/Primary");var holster=hero.skeleton.get_node_or_null("StowThigh/Holster");var sidearm=hero.skeleton.get_node_or_null("StowThigh/Sidearm")
	expect(back!=null and back.visible and holster!=null and sidearm!=null and not sidearm.visible,"pistol drawn: rifle slung, holster empty")
	expect(hero.skeleton.get_node_or_null("StowBelt/Kit0")!=null and hero.skeleton.get_node_or_null("StowBelt/Kit1")!=null,"both frags hang on the belt")
	CarriedGear.apply(hero,CarriedGear.spec_for(p,"a1",false))
	expect(is_instance_valid(back) and not back.visible and sidearm.visible,"drawing the rifle only toggles the stowed copies (no rebuild)")
	expect(back.visibility_range_end>0. and back.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and back.mesh.get_surface_count()==1,"stowed pieces: one merged surface, no shadow, distance culled")
	# Stowed rifle sits on the back: behind the spine, between hips and head.
	await process_frame
	var centre=back.global_transform*back.get_aabb().get_center();var chest=hero.bone_world(hero.bone.Chest).origin;var hips=hero.bone_world(hero.bone.Hips).origin
	var behind=(centre-chest).dot(hero.global_transform.basis.z)
	expect(behind>.05 and centre.y>hips.y and centre.y<hero.head_position().y,"slung rifle rides on the back (%.2f m behind the chest)"%behind)
	# First person view bodies carry nothing; corpses wear what the hero wore.
	var view=HeroCharacter.new();root.add_child(view);view.build(0,0,false);view.first_person_only();CarriedGear.apply(view,spec);view.set_armor(2)
	expect(view.skeleton.get_node_or_null("StowBack")==null and view.skeleton.get_node_or_null("FittedArmor")==null,"first-person body shows no armour or stowed gear")
	var corpse=HeroCharacter.new();root.add_child(corpse);corpse.build(0,0,false);corpse.dress_like(hero)
	expect(corpse.armor_level==2 and corpse.skeleton.get_node_or_null("FittedArmor")!=null and corpse.skeleton.get_node("StowBack/Primary").visible and corpse.skeleton.get_node("StowThigh/Sidearm").visible,"corpse wears the armour and has both weapons stowed")
	# Armour preview: the selected hero wearing the tier.
	var preview=EquipmentPreview.new();root.add_child(preview);await process_frame
	preview.display(3,5,1,"",2,2)
	var worn=preview.model.find_children("FittedArmor","MeshInstance3D",true,false)
	expect(worn.size()==1,"armour preview shows the hero wearing its fitted armour")
	# --- Round 2: balance ---------------------------------------------------------
	var kill_times=[]
	for level in range(1,5):
		var dmg=TurretLogic.bullet_damage(level);var hits=0;var hp=100.
		var rocket_hit=level==4
		if rocket_hit:hp-=TurretLogic.ROCKET_DAMAGE
		while hp>.001:hp-=dmg;hits+=1
		kill_times.append((hits-1)*TurretLogic.INTERVALS[level-1])
	expect(absf(kill_times[0]-3.8)<.1 and absf(kill_times[1]-3.1)<.1 and absf(kill_times[2]-2.4)<.1 and absf(kill_times[3]-1.7)<.1,"turret kills 100 HP in about 3.8 / 3.1 / 2.4 / 1.7 s after the 80%% bullet share %s"%str(kill_times))
	expect(is_equal_approx(TurretLogic.bullet_damage(1),TurretLogic.DAMAGE[0]*.8),"turret bullets deal 80%")
	expect(is_equal_approx(TurretLogic.remote_damage(10.,72.,80.),10.) and is_equal_approx(TurretLogic.remote_damage(10.,104.,80.),4.) and is_equal_approx(TurretLogic.remote_damage(10.,88.,80.),7.) and is_equal_approx(TurretLogic.remote_damage(10.,200.,80.),4.),"TETHER: full to 90% of the turret range, 40% at 130%")
	expect(AbilityBalance.COOLDOWNS[3]==20.,"turret skill cooldown 20 s")
	expect(RocketCombat.flight_lifetime(Vector2(200,200))==10. and TurretLogic.ROCKET_LIFETIME==10.,"every rocket bursts after 10 s")
	var sprint_actor=load("res://scripts/actor.gd")
	expect(sprint_actor.SPRINT_OUT<=.15,"firing out of a sprint waits at most 0.15 s")
	# --- Round 2: reloads ---------------------------------------------------------
	var chime=Catalog.get_weapon("heavy_pistol");var duet=Catalog.get_weapon("dual_pistols")
	expect(chime.reload_style=="revolver" and chime.single_load and is_equal_approx(MagazineReload.duration(chime),float(chime.reload)/float(chime.mag)),"revolvers load round by round within the same total time")
	expect(not MagazineReload.chambered(chime) and not MagazineReload.chambered(duet) and MagazineReload.chambered(Catalog.get_weapon("a1")),"only magazine guns keep a chambered +1")
	expect(ReloadMotion.mag_offset(.4).y<-.5 and ReloadMotion.mag_offset(0.).length()<.001 and ReloadMotion.mag_offset(.9).length()<.001,"the magazine leaves the view mid-reload and is back when seated")
	# Gun lengths: sniper > DMR > MG > AR > shotgun > SMG, longer with more damage.
	var length=func(id:String) -> float:
		var gun=GunModel.new();root.add_child(gun);gun.build(Catalog.get_weapon(id),false)
		var box=AABB();var first=true
		for m in gun.find_children("*","MeshInstance3D",true,false):
			if not m.visible or m.mesh==null:continue
			var b=GunModel.relative(m,gun)*m.get_aabb();box=b if first else box.merge(b);first=false
		gun.free();return box.size.z
	var classes=[["r2","r1"],["r3","r5","r4"],["h2","h1"],["a3","a4","a1","a2"],["e3","e1","m3","e2"],["c3","m2","c1","c4","c2"]]
	var lengths=classes.map(func(ids):return ids.map(func(id):return length.call(id)))
	var ordered=true
	for c in range(classes.size()):
		for k in range(classes[c].size()-1):ordered=ordered and lengths[c][k]>=lengths[c][k+1]-.005
		if c+1<classes.size():ordered=ordered and lengths[c].min()>lengths[c+1].max()
	expect(ordered,"gun lengths follow class and damage %s"%str(lengths.map(func(l):return l.map(func(x):return snappedf(x,.01)))))
	# Support hands: AK bases hold the magazine, Sniper_2 bases a real forend.
	var vector=GunModel.new();root.add_child(vector);vector.build(Catalog.get_weapon("a1"),false)
	var mag_centre=ReloadMotion.magazine(vector,vector.base.scale,Vector3.ZERO)[0]
	expect(vector.left_grip.position.distance_to(mag_centre/vector.base.scale.x)<.08,"AK-base support hand closes round the magazine")
	vector.free()
	var scout=GunModel.new();root.add_child(scout);scout.build(Catalog.get_weapon("r1"),false)
	expect(scout.get_node_or_null("Handguard")!=null,"Sniper_2 base has a forend for the support hand")
	scout.free()
	var tidal=GunModel.new();root.add_child(tidal);tidal.build(Catalog.get_weapon("e2"),false)
	expect(is_instance_valid(tidal.magazine),"TIDAL has a box magazine to reload")
	tidal.free()
	# --- Round 2: in a match ------------------------------------------------------
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	for i in range(6):await process_frame
	g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.options.mode=0;g.build_world();g.add_player(1,"P","t142")
	g.phase="combat";g.clock=100.
	var hands=[]
	for i in range(40):g.spawn(1);hands.append(int(g.players[1].hand))
	expect(hands.all(func(h):return h==1),"a player's hands never swap sides between lives")
	var gp=g.players[1];var ga=g.actors[1]
	g.spawn(1)
	expect(not g.can_attack(gp),"no attack right after respawning")
	g.clock+=Rules.SPAWN_ATTACK_DELAY+.01
	expect(g.can_attack(gp) and float(gp.protect)>g.clock,"attack allowed after one second, still protected")
	g.clock+=5.
	expect(is_equal_approx(BombLogic.radius(g),2.*minf(30.,minf(g.arena.bounds.x,g.arena.bounds.y)*.4)),"bomb blast reach doubled")
	expect(is_equal_approx(TurretLogic.range_for(g,4),TurretLogic.range_for(g,1)*1.3),"each turret upgrade adds a tenth of the level-1 range")
	# DUET: half the rounds when the first pistol comes back, the rest at the end.
	gp.secondary="dual_pistols";gp.slot=1;gp.mag["dual_pistols"]=0;gp.reserve["dual_pistols"]=100;gp.reload=0.;gp.alive=true;gp.protect=0.
	g.begin_reload(1)
	var d=MagazineReload.duration(duet)
	g.clock+=d*.55;MagazineReload.tick(g,1)
	expect(int(gp.mag["dual_pistols"])==12 and gp.reload>g.clock,"DUET: first pistol loaded halfway through (12)")
	g.clock+=d*.5;MagazineReload.finish(g,1)
	expect(int(gp.mag["dual_pistols"])==24,"DUET: both pistols full at the end")
	# Revolver: a shot mid-load fires at once and stops the loading.
	gp.secondary="heavy_pistol";gp.slot=1;gp.mag["heavy_pistol"]=2;gp.reserve["heavy_pistol"]=30;gp.reload=0.;gp.fire_ready=0.
	g.begin_reload(1)
	expect(gp.reload>g.clock and gp.reload-g.clock<=MagazineReload.duration(chime)+.001,"revolver loads one round per cycle")
	ga.input_state.fire=true;ga.input_state.trigger_seq=int(ga.input_state.get("trigger_seq",0))+1;ga.last_sprint=false;ga.sprint_release=0.
	g.process_trigger(1)
	expect(gp.reload<=0. and gp.fire_ready<=g.clock+float(chime.interval)+.001 and int(gp.mag["heavy_pistol"])==1,"revolver fires at once mid-load and stops loading")
	ga.input_state.fire=false
	g.queue_free()
	print("V142_RESULT %d/%d"%[checks-failures,checks])
	quit(1 if failures>0 else 0)
