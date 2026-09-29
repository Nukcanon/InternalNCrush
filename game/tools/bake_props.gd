extends SceneTree
## Bakes Toon Shooter Game Kit (CC0, Quaternius) environment pieces into single
## vertex-colour meshes (assets/props/<name>.res) drawn with the world surface
## material, plus assets/props/manifest.json with each prop's footprint.
## Pivot: centre of the footprint on the ground; heights are real-world metres.
## Run with "-- measure" to print the source sizes only.
const DIR="res://../../.tools/quaternius-toonshooter/env/"
# Source name -> target height (m). Width/depth follow proportionally.
const PROPS={
	"StreetLight":4.6,"Tree_1":5.2,"Tree_2":5.0,"Tree_3":5.4,"Tree_4":4.4,
	"TrafficCone":.7,"Crate":.9,"ExplodingBarrel":.95,"Pallet":.16,"Pallet_Broken":.2,
	"CardboardBoxes_1":.5,"CardboardBoxes_2":.9,"CardboardBoxes_3":1.9,"CardboardBoxes_4":1.5,
	"TrashContainer":1.4,"Barrier_Single":.85,"SackTrench":1.0,"SackTrench_Small":.95,
	"Container_Long":2.6,"Container_Small":2.6,"GasTank":1.4,"GasCan":.45,
	"WaterTank_Floor":2.0,"WaterTank_Platform":4.2,"Sofa":.85,"Sofa_Small":.85,"Sign":2.3,"Pipes":1.0,
	"Fence":1.1,"Fence_Long":1.1,"MetalFence":2.1,"WoodPlanks":.15,"Debris_Pile":.2,"Debris_Tires":.75}
func _initialize():call_deferred("run")
func run():
	var measure=OS.get_cmdline_user_args().has("measure")
	DirAccess.make_dir_recursive_absolute("res://assets/props")
	var manifest={}
	for name in PROPS:
		var result=bake(name,float(PROPS[name]),measure)
		if not result.is_empty():manifest[name.to_lower()]=result
	if not measure:
		var f=FileAccess.open("res://assets/props/manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify(manifest,"\t"));f.close()
	print("PROP_BAKE_OK ",manifest.size());quit()
func bake(name:String,height:float,measure:bool) -> Dictionary:
	var doc=GLTFDocument.new();var state=GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(DIR+name+".gltf"),state)!=OK:push_error("missing "+name);return {}
	var scene:Node3D=doc.generate_scene(state);root.add_child(scene)
	var verts=PackedVector3Array();var norms=PackedVector3Array();var colors=PackedColorArray()
	for mesh_node in scene.find_children("*","MeshInstance3D",true,false):
		var xf:Transform3D=mesh_node.global_transform
		for s in range(mesh_node.mesh.get_surface_count()):
			var arrays=mesh_node.mesh.surface_get_arrays(s);var mat=mesh_node.mesh.surface_get_material(s)
			var color:Color=mat.albedo_color if mat is BaseMaterial3D else Color.WHITE
			var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var n:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var idx=arrays[Mesh.ARRAY_INDEX]
			if idx==null or idx.is_empty():idx=range(v.size())
			for i in idx:verts.append(xf*v[i]);norms.append((xf.basis*n[i]).normalized());colors.append(color)
	scene.queue_free()
	var lo=Vector3.INF;var hi=-Vector3.INF
	for p in verts:lo=lo.min(p);hi=hi.max(p)
	var size=hi-lo
	if measure:print("MEASURE ",name," ",size);return {}
	var scale=height/maxf(size.y,.001)
	var pivot=Vector3((lo.x+hi.x)*.5,lo.y,(lo.z+hi.z)*.5)
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(verts.size()):
		st.set_color(colors[i]);st.set_normal(norms[i]);st.add_vertex((verts[i]-pivot)*scale)
	st.index();var mesh=st.commit()
	ResourceSaver.save(mesh,"res://assets/props/"+name.to_lower()+".res",ResourceSaver.FLAG_COMPRESS)
	var out=size*scale
	print(name," size ",out," tris ",verts.size()/3)
	return {"size":[snappedf(out.x,.01),snappedf(out.y,.01),snappedf(out.z,.01)],"tris":verts.size()/3}
