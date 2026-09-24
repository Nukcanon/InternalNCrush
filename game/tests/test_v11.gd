extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	expect(Rules.WALK_SPEED<=3.3 and Rules.RUN_SPEED<=6.3,"human-scale locomotion caps")
	expect(not GraphicsOptions.blood_enabled,"blood is disabled before profile load")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.ui.clear_panel();g.set_physics_process(false)
	g.render_actors=false;g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.build_world();g.add_player(1,"Target","test_v11")
	var actor:Actor=g.actors[1];actor.position=Vector3(0,3,0);actor.rotation=Vector3.ZERO;actor.ensure_hit_pose()
	var rig=actor.character.rig
	for part in [["Hips/Chest/Head","head"],["Hips/Chest","torso"],["Hips/LeftLeg/Knee","legs"]]:
		var p=rig.get_node(part[0]).global_position
		if part[1]=="legs":p.y-=.16
		var hit=AnatomicalHit.trace(actor,p+Vector3.BACK*2,p+Vector3.FORWARD*2)
		expect(not hit.is_empty() and hit.zone==part[1],"anatomical zone "+part[1])
	var empty=actor.global_position+Vector3(.37,1.55,0)
	expect(AnatomicalHit.trace(actor,empty+Vector3.BACK*2,empty+Vector3.FORWARD*2).is_empty(),"space beside head/shoulders is not hittable")
	var chest=rig.get_node("Hips/Chest").global_position
	var blocker=StaticBody3D.new();g.add_child(blocker);blocker.position=chest+Vector3.BACK
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(.8,.8,.1);shape.shape=box;blocker.add_child(shape)
	await physics_frame;await physics_frame
	var blocked=g.ray(chest+Vector3.BACK*2,chest+Vector3.FORWARD*2,[],1|2)
	expect(not blocked.is_empty() and blocked.collider==blocker,"world occlusion wins over character volume")
	blocker.free()
	g.profile.blood_effects=false;GraphicsOptions.apply(g)
	g.combat_fx.blood_hit(chest,Vector3.BACK,1.)
	expect(not is_instance_valid(g.combat_fx.blood),"blood off creates no particles or stains")
	var geo=Node3D.new();root.add_child(geo)
	for i in range(2):
		var item=MeshInstance3D.new();item.mesh=BoxMesh.new();item.material_override=StandardMaterial3D.new();geo.add_child(item);item.rotation.y=.42;item.position=Vector3(i*.2,0,0)
	# Same-height rotated top/bottom faces overlap even though their side planes differ.
	expect(PlanarCleanup.clean(geo)>0,"rotated coplanar surfaces are clipped")
	expect(PlanarCleanup.clean(geo)==0,"coplanar cleanup is idempotent")
	geo.free()
	var hand_styles={}
	for id in Catalog.weapons:
		var weapon=WeaponVisual.new();root.add_child(weapon);weapon.build(Catalog.weapons[id],true);hand_styles[weapon.reload_style]=true
		for side in [-1.,1.]:
			weapon.scale.x=side
			for t in [-1.,.2,.4,.6,.8,1.]:
				weapon.animate_reload(t,0.,1.)
				expect(weapon.support_rig.basis.determinant()>.99 and weapon.firing_rig.basis.determinant()>.99,"wrist axes remain orthonormal "+id)
		weapon.free()
	expect(hand_styles.has_all(["bullpup","drum","bolt","shell","box","pistol"]),"magazine-specific feeding animations")
	var filter=RoomFilters.defaults();filter.ping=100
	var rooms=[{"name":"Beta","mode":0,"players":4,"ping":80},{"name":"Alpha","mode":1,"players":2,"ping":30},{"name":"Unknown","mode":0,"players":1,"ping":-1}]
	var matches=RoomFilters.select(rooms,filter)
	expect(matches.size()==2 and matches[0].name=="Alpha","max ping excludes unknown and sorts names")
	filter.mode=0;filter.name="bet";matches=RoomFilters.select(rooms,filter)
	expect(matches.size()==1 and matches[0].name=="Beta","combined case-insensitive name/mode filter")
	# A pose-only host rig is replaced when rendering is enabled.
	g.render_actors=true;actor.ensure_character()
	expect(actor.character.rig.has_node("ContinuousBody"),"host switches pose-only actor to rendered model")
	g.leave_game();g.free();await process_frame
	print("V11_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
