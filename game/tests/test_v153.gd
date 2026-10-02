extends SceneTree
# 1.5.3 (the user): the heavy's shield cuts only hits whose line passes through its panel
# (a shot beside it from the front used to be cut too), and every magazine gun seats its
# magazine with the pistol's click.
var checks=0
var failures=0
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	for id in ["a1","a2","c1","h1","r2"]:
		expect(ReloadAudio.cues(Catalog.get_weapon(id),10).any(func(e):return e[1]=="pistol_magazine"),Catalog.get_weapon(id).name+" seats its magazine with the pistol's click")
	expect(ReloadAudio.cues(Catalog.get_weapon("h6"),10).any(func(e):return e[1]=="magazine"),"ARC's battery keeps its own sound")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(50,50);g.arena.has_water=false;g.arena.box(Vector3(0,-.5,0),Vector3(100,1,100),Color.GRAY)
	g.add_player(1,"Heavy","h");g.add_player(2,"Enemy","e")
	g.phase="combat";g.clock=100.;g.options.mode=0
	var p=g.players[1];var e=g.players[2];p.team=0;e.team=1;p.role=2;p.protect=0.;p.invulnerable=0.;p.armor=0.;p.hp=100.;p.shield=g.clock+6.
	var a=g.actors[1];a.position=Vector3.ZERO;a.aim_yaw=0.;g.actors[2].position=Vector3(4,0,-2.5)
	var head=Vector3(0,1.6,0)
	g.damage(1,10.,2,false,"a1",Vector3(0,1.5,-6),head)
	expect(is_equal_approx(p.hp,98.5),"a shot through the panel from the front is cut 85%% (hp %s)"%p.hp)
	p.hp=100.;p.shield_ding_at=-1.
	g.damage(1,10.,2,false,"a1",Vector3(4,1.5,-2.5),head)
	expect(is_equal_approx(p.hp,90.),"a shot from the front-side passing beside the panel is not cut (hp %s)"%p.hp)
	p.hp=100.
	g.damage(1,10.,2,false,"a1",Vector3(0,1.5,6),head)
	expect(is_equal_approx(p.hp,90.),"a shot from behind is not cut (hp %s)"%p.hp)
	p.hp=100.
	g.damage(1,10.,2,false,"a1",Vector3(0,6.,-1.5),head) # (crosses the panel's plane 3.9 m up)
	expect(is_equal_approx(p.hp,90.),"a shot from above, over the panel's top, is not cut (hp %s)"%p.hp)
	p.hp=100.;a.aim_yaw=PI*.5
	g.damage(1,10.,2,false,"a1",Vector3(-6,1.5,0),head)
	expect(is_equal_approx(p.hp,98.5),"the panel turns with the aim (hp %s)"%p.hp)
	print("V153_RESULT %d/%d"%[checks-failures,checks])
	g.free()
	quit(1 if failures>0 else 0)
