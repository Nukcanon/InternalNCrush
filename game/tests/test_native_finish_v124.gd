extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	var male_texture=SurfaceFinish.human_material(0).get_shader_parameter("anatomy_detail")
	expect(male_texture==SurfaceFinish.human_material(2).get_shader_parameter("anatomy_detail"),"male roles share one detail texture")
	var female_texture=SurfaceFinish.human_material(1).get_shader_parameter("anatomy_detail")
	expect(female_texture==SurfaceFinish.human_material(5).get_shader_parameter("anatomy_detail"),"female roles share one detail texture")
	for role in [0,1,5]:
		var data=AuthoredHuman.source(role);var crossed=0
		for face in data.faces:
			var lo=INF;var hi=-INF
			for index in face:lo=minf(lo,data.vertices[index][1]);hi=maxf(hi,data.vertices[index][1])
			if lo<1.47999 and hi>1.48001:crossed+=1
		expect(crossed==0,"skin and shirt have a real cut neckline, role "+str(role))
		expect(data.faces.size()<=27000,"native anatomical triangle budget remains below 27k")
		var rig=CharacterVisual.make_rig(role,0);root.add_child(rig);OperatorSkin.install(rig,str(role)+"_finish")
		expect(rig.get_node("DeformSkeleton").get_bone_count()==15,"existing skeletal budget preserved")
		rig.free()
	var holder=Node3D.new();root.add_child(holder)
	var hand=WeaponHand.new();holder.add_child(hand);hand.build(true,false,1)
	var shared=hand.handed_mesh.get_child(0).mesh
	hand.free();var warm=HumanModel.loft_meshes.size();var elapsed=[]
	for i in range(40):
		var start=Time.get_ticks_usec();hand=WeaponHand.new();holder.add_child(hand);hand.build(i%2==0,false,1)
		expect(hand.handed_mesh.get_child(0).mesh==shared,"weapon hand geometry shared across swaps")
		hand.free();elapsed.append((Time.get_ticks_usec()-start)/1000.)
	expect(HumanModel.loft_meshes.size()==warm,"hand swaps do not grow mesh cache")
	expect(HumanModel.loft_meshes.size()<=HumanModel.LOFT_CACHE_LIMIT,"loft cache has a fixed limit")
	GraphicsOptions.physics_effects=0;var fx=CombatFX.new();holder.add_child(fx)
	for i in range(8):fx.explosion(Vector3(i,0,0))
	var first=fx.explosion_pool[0];var material=first.puffs[0].material;var nodes=fx.get_child_count()
	var memory=[]
	for cycle in range(30):
		fx.clear(true);await process_frame;await process_frame
		for i in range(8):fx.explosion(Vector3(i,0,0),cycle%2==0)
		memory.append(int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
		expect(fx.explosion_pool.size()==8 and fx.get_child_count()==nodes,"explosion pool stays bounded")
		expect(fx.explosion_pool[0]==first and first.puffs[0].material==material,"explosion meshes and materials reused")
		expect(first.puffs.size()==24 and first.puffs[0].node.mesh==first.puffs[-1].node.mesh,"fire/dust appearance retained with one shared quad")
	expect(memory[-1]<=memory[1]+2,"repeated bursts do not retain new resources")
	fx.clear();await process_frame;await process_frame
	expect(fx.get_child_count()==0 and fx.explosion_pool.is_empty(),"leaving releases retained effect pool")
	GraphicsOptions.physics_effects=2
	for i in range(12):fx.explosion(Vector3.ZERO)
	expect(BurstVisual.debris_shapes.size()<=3,"debris uses three fixed shared collision shapes")
	fx.clear();await process_frame;await process_frame
	expect(BurstVisual.debris_count==0,"all decorative rigid bodies released")
	holder.free();await process_frame
	print("NATIVE_FINISH_RESULT ",checks-failures,"/",checks," hand_swap_ms=",elapsed," burst_resource_samples=",memory)
	quit(1 if failures else 0)
