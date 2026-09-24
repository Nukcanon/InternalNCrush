class_name DeploymentSilhouette
extends RefCounted

static func apply(node:Node3D,device:Dictionary,local_id:int):
	var owned=local_id>0 and int(device.owner)==local_id
	var key="%s:%s:%s"%[owned,device.team,device.get("level",1)]
	if node.get_meta("silhouette_state","")==key:return
	node.set_meta("silhouette_state",key)
	var material:StandardMaterial3D=null
	if owned:
		material=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.no_depth_test=true;material.disable_receive_shadows=true
		material.albedo_color=Color("48baff") if int(device.team)==0 else Color("ff983e")
		material.albedo_color.a=.62;material.render_priority=120
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		mesh.material_overlay=material
