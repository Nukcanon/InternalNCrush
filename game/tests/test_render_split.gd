extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	var world=SurfaceFinish.world_material();var human=SurfaceFinish.human_material()
	if RenderStyle.web():
		expect("toon_surface" in world.shader.code,"Web retains comic paint")
		expect(not "normalize(VIEW)" in world.shader.code,"camera grazing angle cannot blacken distant floors")
		expect("paint * 0.28" in world.shader.code,"lit Web paint has a readability floor")
	else:
		expect("material_atlas" in world.shader.code,"native retains detailed architecture atlas")
		expect("finish_metallic" in SurfaceFinish.equipment_material().shader.code,"native equipment retains metal response")
		expect(not "sampler2D skin_texture" in human.shader.code,"native skin is painted, not photographic")
	var host=Node3D.new();root.add_child(host)
	var mesh=MeshFactory.box(host,Vector3.ZERO,Vector3.ONE,Color.GRAY);mesh.material_override=world
	WebMaterials.apply(host)
	expect(RenderStyle.web() or mesh.material_override==world,"Web conversion cannot replace native world materials")
	host.free()
	var model=CharacterVisual.make_rig(0,0);root.add_child(model);OperatorSkin.install(model,"0_split")
	var body=model.get_node("ContinuousBody");var count=body.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()
	expect(count<18000 if RenderStyle.web() else count>18000,"platform selects its own operator geometry")
	model.free()
	print("RENDER_SPLIT_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
