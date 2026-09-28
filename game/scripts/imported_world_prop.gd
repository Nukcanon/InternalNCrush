class_name ImportedWorldProp
extends RefCounted
## Shared CC0 silhouettes. Scale once at build time, retain original UV palette.
static var scenes={}
static var palettes={}
static var geometry={}
static func build(parent:Node3D,asset:String,max_size:Vector3,pack:String="industrial",metre_scale:bool=false):
	var key=pack+"/"+asset;var palette_path="res://assets/models/"+pack+"/Textures/colormap.png"
	if not palettes.has(pack):palettes[pack]=load(palette_path) if ResourceLoader.exists(palette_path) else null
	if not scenes.has(key):
		var baked="res://assets/door_leaves/"+asset+".scn"
		scenes[key]=load(baked) if pack=="doors_original" and ResourceLoader.exists(baked) else load("res://assets/models/"+key+".glb")
	var model=scenes[key].instantiate();parent.add_child(model)
	var list=model.find_children("*","MeshInstance3D",true,false);var bounds=AABB();var first=true
	for mesh in list:
		var local=parent.global_transform.affine_inverse()*mesh.global_transform
		var geometry_key=key+":"+str(model.get_path_to(mesh))
		if not geometry.has(geometry_key):
			var shared=mesh.mesh.duplicate(true)
			for surface in range(shared.get_surface_count()):
				var source=mesh.get_active_material(surface)
				var material=source.duplicate() as StandardMaterial3D if source is StandardMaterial3D else StandardMaterial3D.new()
				if palettes[pack]!=null:material.albedo_texture=palettes[pack]
				material.set_meta("authored_world",true);material.roughness=.85;material.metallic=0.;material.normal_enabled=false
				shared.surface_set_material(surface,material)
			geometry[geometry_key]=shared
		mesh.mesh=geometry[geometry_key]
		var box=local*mesh.get_aabb();bounds=box if first else bounds.merge(box);first=false
	var factor=minf(max_size.x/bounds.size.x,minf(max_size.y/bounds.size.y,max_size.z/bounds.size.z))
	if metre_scale:factor=1.
	for mesh in list:
		var local=parent.global_transform.affine_inverse()*mesh.global_transform
		mesh.reparent(parent);local.origin-=(bounds.position+Vector3(bounds.size.x*.5,0,bounds.size.z*.5));local.origin*=factor;local.basis=local.basis.scaled(Vector3.ONE*factor);mesh.transform=local
		mesh.set_meta("imported_world",true)
		for i in range(mesh.mesh.get_surface_count()):
			var material=mesh.mesh.surface_get_material(i) as StandardMaterial3D
			# The GLB references an external palette. Embed it explicitly so an
			# earlier import with a missing dependency cannot leave a white model.
			if palettes[pack]!=null:material.albedo_texture=palettes[pack]
			material.set_meta("authored_world",true);material.roughness=.85;material.metallic=0.;material.normal_enabled=false
			mesh.mesh.surface_set_material(i,material)
			mesh.set_surface_override_material(i,PropFinish.material(material,pack))
	model.free()
