extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	var world=Node3D.new();root.add_child(world)
	for id in Catalog.weapons:
		var gun=WeaponVisual.new();world.add_child(gun);gun.build(Catalog.get_weapon(id),true,false)
		expect(gun.support_rig.handed_mesh.scale.x==-1. and gun.firing_rig.handed_mesh.scale.x==1.,"distinct anatomical left/right hands: "+id)
		expect(is_equal_approx(gun.support_rig.basis.get_scale().length()/gun.firing_rig.basis.get_scale().length(),WeaponHand.SUPPORT_SCALE),"proportional support hand enlargement: "+id)
		for hand in [-1.,1.]:
			gun.scale.x=hand
			for phase in [-1.,.10,.30,.45,.60,.78,.90,1.]:
				gun.animate_reload(phase,0.)
				expect(gun.left_hand.position.is_finite() and gun.right_hand.position.is_finite() and absf(gun.support_rig.basis.determinant())>.01,"finite wrists through handed reload: "+id)
				expect(gun.support_rig.contact_state.size()==2 and gun.support_rig.contact_state[1].size()==3,"receiver/grip/magazine contact constraints present: "+id)
		gun.free()
	var turret={"yaw":0.,"head_yaw":-TurretLogic.HALF_ARC,"patrol_side":1.}
	for i in range(120):TurretLogic.patrol(turret,1./60.)
	expect(absf(turret.head_yaw-TurretLogic.HALF_ARC)<.0001,"patrol crosses its full arc in two seconds")
	for i in range(120):TurretLogic.patrol(turret,1./60.)
	expect(absf(turret.head_yaw+TurretLogic.HALF_ARC)<.0001,"patrol returns in four seconds")
	var target=Basis(Vector3.UP,TurretLogic.HALF_ARC)*Vector3.FORWARD
	var aligned=TurretLogic.track(turret,target,.1)
	expect(not aligned and turret.head_yaw<0.,"turret cannot shoot immediately across the arc")
	for i in range(21):aligned=TurretLogic.track(turret,target,1./60.)
	expect(aligned and absf(turret.head_yaw-TurretLogic.HALF_ARC)<.001,"tracking covers the arc in 0.45 seconds")
	expect(is_equal_approx(TurretLogic.ALERT_DELAY,.1),"recognition chirp reserves 0.1 seconds before tracking")
	var touch=TouchControls.new();root.add_child(touch)
	for row in [["skill","gadget","use","medical"],["slot0","slot1","slot2","slot3"]]:
		var first:Rect2=touch.buttons[row[0]];var last:Rect2=touch.buttons[row[-1]]
		expect(is_equal_approx((first.position.x+last.end.x)*.5,640.),"mobile action row centred on screen")
	touch.free()
	var material=ToonMaterials.vertex_material();var shader=material.shader;var code=shader.code
	ToonMaterials.configure(true);ToonMaterials.configure(false)
	expect(shader==material.shader and code==shader.code,"graphics changes do not compile a new shader")
	var high_auto=WebGraphics.resolve({"web_quality":-1},2)
	expect(high_auto.antialias==0 and high_auto.shadow_quality==0 and high_auto.lighting_quality==0,"automatic mode avoids mid-combat GPU buffer changes")
	world.free();await process_frame
	print("DETAILS_V116_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
