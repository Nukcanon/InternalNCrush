extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	var mono=Catalog.get_weapon("r2");var scout=Catalog.get_weapon("r1")
	for spec in [["head",300.],["torso",150.],["hands",90.],["feet",90.]]:expect(is_equal_approx(CombatBalance.damage_at(mono,20.,spec[0]),spec[1]),"MONOLITH "+spec[0])
	expect(scout.damage==80.,"SCOUT base 80")
	for id in ["r1","r2","r3","r4","r5","a1"]:
		var w=Catalog.get_weapon(id);var scale=.4 if id in ["r1","r2"] else .6 if id in ["r3","r4","r5"] else 1.
		for distance in [5.,100.,250.]:expect(is_equal_approx(CombatBalance.structure_damage(w,distance),CombatBalance.damage_at(w,distance)*scale),"structure damage includes distance "+id)
	for variant in range(3):
		var p={"role":3,"gadget":variant};GadgetLoadout.reset(p);expect(p.gadget_count==4-variant,"cover stock per type")
	for id in ["e1","m3"]:
		var events=ReloadAudio.cues(Catalog.get_weapon(id),5)
		expect(events.filter(func(e):return e[1]=="shell_insert").size()==5,"one sound per loaded shell")
		expect(events[-1][1]=="bolt","shell-fed action finishes after inserts")
	expect(not ReloadAudio.cues(Catalog.get_weapon("e3"),2).any(func(e):return e[1]=="bolt"),"break-action has no fictitious charging handle")
	for id in ["a1","r2","pistol"]:expect(ReloadAudio.cues(Catalog.get_weapon(id),10)[1][1]=="magazine","magazine insertion cue")
	var holder=Node3D.new();root.add_child(holder)
	var native=ArmorVisual.build(holder,2,false);var web=ArmorVisual.build(holder,2,true)
	var ncount=0;var wcount=0
	for mesh in native.find_children("*","MeshInstance3D",true,false):ncount+=mesh.mesh.surface_get_array_len(0)
	for mesh in web.find_children("*","MeshInstance3D",true,false):wcount+=mesh.mesh.surface_get_array_len(0)
	expect(ncount>wcount,"native vest has more geometry detail")
	var detailed=BulletMark.make(false);var simple=BulletMark.make(true);holder.add_child(detailed);holder.add_child(simple)
	expect(detailed.get_child_count()>simple.get_child_count(),"native crater has actual relief")
	var scratch=MeleeMark.make(false,false);holder.add_child(scratch);expect(scratch.get_child_count()>0,"native slash relief")
	holder.free()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80);g.arena.has_water=false;g.arena.box(Vector3(0,-.5,0),Vector3(160,1,160),Color.GRAY)
	g.add_player(1,"Builder","builder");g.add_player(2,"TargetNick","target");g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.role=3;p.primary="e1";p.gadget=0;p.team=0
	var q=g.players[2];q.protect=0.;q.team=1
	g.ui.show_hud();g.damage(2,1000.,1)
	expect(g.ui.banner.text==str(q.nick)+" 처치","kill confirmation names victim")
	g.spawn(2);q.protect=0.
	var cover=g.add_device("cover",Vector3(20,0,20),1,180.);var turret=g.add_device("turret",Vector3(26,0,20),1,180.)
	g.damage(1,1000.,2);expect(g.devices.has(cover) and not g.devices.has(turret),"death preserves cover and removes turret")
	expect(g.devices[cover].expires>g.clock+100000.,"cover does not disappear after three minutes")
	g.spawn(1);expect(p.gadget_count==4 and g.devices.has(cover),"respawn restocks without deleting cover")
	p.protect=0.;p.gadget=2;p.gadget_count=2;p.placing="cover";g.actors[1].position=Vector3(40,0,40);g.actors[1].reset_view(0.)
	await physics_frame;await physics_frame
	p.placing="";expect(not ActionState.available(g,1,"gadget"),"heavy cover button respects survivor limit");p.placing="cover"
	expect(not Deployment.confirm(g,1) and p.gadget_count==2,"heavy cover limit counts surviving cover and does not consume stock")
	g.remove_device(cover);p.placing="cover"
	expect(Deployment.confirm(g,1) and p.gadget_count==1,"heavy cover deploys with free slot")
	var built=g.devices.keys()[0];g.clock+=1.;g.damage_device(built,20.,2)
	expect(g.devices[built].hp<g.devices[built].max_hp,"unfinished cover keeps damage and construction vulnerability")
	# Walking contact must displace small props on an actual floor.
	for kind in ["canister","tire","barrel"]:
		var prop=InteractiveProp.new();prop.position=Vector3(0,1.,-3);prop.configure(1,kind,true);g.arena.add_child(prop)
		for i in range(30):await physics_frame
		var before=prop.position
		for i in range(30):prop.push_by_character(Vector3.RIGHT,3.2,1./60.);await physics_frame
		expect(prop.position.x>before.x+.25,"walk force overcomes floor friction "+kind);prop.free()
	g.free();await process_frame
	print("V122_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
