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
		expect("paint * 0.22" in world.shader.code,"lit Web paint has a readability floor (1.4.2: slightly deeper shade)")
	else:
		expect("material_atlas" in world.shader.code,"native retains detailed architecture atlas")
		expect("finish_metallic" in SurfaceFinish.equipment_material().shader.code,"native equipment retains metal response")
		var detail:Texture2D=human.get_shader_parameter("anatomy_detail")
		expect(detail!=null and detail.get_width()<=512 and detail.get_height()<=512,"native CC0 skin detail has a fixed 512px budget")
	var host=Node3D.new();root.add_child(host)
	var mesh=MeshFactory.box(host,Vector3.ZERO,Vector3.ONE,Color.GRAY);mesh.material_override=world
	WebMaterials.apply(host)
	expect(RenderStyle.web() or mesh.material_override==world,"Web conversion cannot replace native world materials")
	host.free()
	var model=HeroCharacter.new();root.add_child(model);model.build(0,0)
	expect(model.meshes().size()>=4,"hero outfit keeps its body, head, legs and feet parts")
	model.free()
	print("RENDER_SPLIT_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
