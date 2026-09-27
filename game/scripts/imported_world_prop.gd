class_name ImportedWorldProp
extends RefCounted
## Shared CC0 silhouettes. Scale once at build time, retain original UV palette.
static var scenes={}
static var palettes={}
static func build(parent:Node3D,asset:String,max_size:Vector3,pack:String="industrial"):
	var key=pack+"/"+asset;var palette_path="res://assets/models/"+pack+"/Textures/colormap.png"
	if not palettes.has(pack):palettes[pack]=load(palette_path) if ResourceLoader.exists(palette_path) else null
	if not scenes.has(key):scenes[key]=load("res://assets/models/"+key+".glb")
	var model=scenes[key].instantiate();parent.add_child(model)
	var list=model.find_children("*","MeshInstance3D",true,false);var bounds=AABB();var first=true
	for mesh in list:
		var local=parent.global_transform.affine_inverse()*mesh.global_transform
		mesh.mesh=mesh.mesh.duplicate(true)
		var box=local*mesh.get_aabb();bounds=box if first else bounds.merge(box);first=false
	var factor=minf(max_size.x/bounds.size.x,minf(max_size.y/bounds.size.y,max_size.z/bounds.size.z))
	for mesh in list:
		var local=parent.global_transform.affine_inverse()*mesh.global_transform
		mesh.reparent(parent);local.origin-=(bounds.position+Vector3(bounds.size.x*.5,0,bounds.size.z*.5));local.origin*=factor;local.basis=local.basis.scaled(Vector3.ONE*factor);mesh.transform=local
		mesh.set_meta("imported_world",true)
		for i in range(mesh.mesh.get_surface_count()):
			var material=mesh.get_active_material(i).duplicate() as StandardMaterial3D
			# The GLB references an external palette. Embed it explicitly so an
			# earlier import with a missing dependency cannot leave a white model.
			if palettes[pack]!=null:material.albedo_texture=palettes[pack]
			material.set_meta("authored_world",true);material.roughness=.85;material.metallic=0.;material.normal_enabled=false
			mesh.mesh.surface_set_material(i,material)
			mesh.set_surface_override_material(i,material)
	model.free()
