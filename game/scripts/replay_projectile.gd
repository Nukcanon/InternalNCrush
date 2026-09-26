class_name ReplayProjectile
extends RefCounted
# This mesh exists only in the replay stage: normal ballistics remain ray based.
static func make(parent:Node3D) -> Node3D:
	var projectile=Node3D.new();projectile.name="ReplayBullet";parent.add_child(projectile)
	var copper=Color("b97a45")
	var mesh=HumanModel.loft(projectile,Vector3.ZERO,[Vector4(-.023,.0068,.0068,0),Vector4(-.020,.0075,.0075,0),Vector4(.001,.0075,.0075,0),Vector4(.011,.0058,.0058,0),Vector4(.020,.0029,.0029,0),Vector4(.024,.0003,.0003,0)],copper,8 if RenderStyle.web() else 16)
	var material=StandardMaterial3D.new();material.albedo_color=copper;material.metallic=.72;material.roughness=.29
	mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A small copper jacket band catches replay lighting without an added light.
	var band=MeshFactory.cylinder(projectile,Vector3(0,-.013,0),.0077,.003,Color("cf9459"),Vector3.ZERO,-1.,8 if RenderStyle.web() else 16)
	band.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return projectile
