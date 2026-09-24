class_name WebPropBatch
extends Node3D
# Shared visual draw calls only; authoritative rigid bodies/colliders remain untouched.
var batches=[]
var members=[]
func build(props:Dictionary):
	var groups={}
	for prop in props.values():
		var key=prop.kind+str(prop.prop_id%2 if prop.kind=="barrel" else 0)
		var meshes=[]
		for child in prop.get_children():
			if child is MeshInstance3D and child.visible:meshes.append(child)
		# Current props use one merged opaque surface. Keep unsupported shapes unchanged.
		if meshes.size()!=1:continue
		var mesh:MeshInstance3D=meshes[0]
		if not groups.has(key):groups[key]=[]
		groups[key].append({"body":prop,"mesh":mesh})
	for key in groups:
		var list:Array=groups[key]
		if list.size()<2:continue
		var source:MeshInstance3D=list[0].mesh
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=source.mesh;mm.instance_count=list.size()
		var display=MultiMeshInstance3D.new();display.multimesh=mm;display.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material=source.get_active_material(0)
		if material:display.material_override=WebMaterials.simplify(material)
		add_child(display);batches.append(display)
		for i in range(list.size()):
			var item=list[i];var pose=global_transform.affine_inverse()*item.mesh.global_transform
			mm.set_instance_transform(i,pose);item.mesh.hide()
			members.append({"source":item.mesh,"batch":mm,"index":i,"pose":pose})
func _process(_dt):
	for item in members:
		if not is_instance_valid(item.source):continue
		var pose=global_transform.affine_inverse()*item.source.global_transform
		if pose!=item.pose:item.batch.set_instance_transform(item.index,pose);item.pose=pose
