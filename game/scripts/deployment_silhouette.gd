class_name DeploymentSilhouette
extends RefCounted
# Only occluded fragments are tinted. Visible surfaces keep their original material.
static var materials={}
static func material_for(team:int,bounds:AABB) -> ShaderMaterial:
	var key=str([team,bounds])
	if materials.has(key):return materials[key]
	var shader=Shader.new()
	shader.code="""shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_back;
uniform sampler2D world_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec4 team_color : source_color;
uniform vec3 bounds_min;
uniform vec3 bounds_max;
void fragment() {
    float depth = texture(world_depth, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    if (OUTPUT_IS_SRGB) { ndc.z = depth * 2.0 - 1.0; }
    vec4 scene = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    float scene_distance = -scene.z / scene.w;
    float target_distance = -VERTEX.z;
    vec3 blocker = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(scene.xyz / scene.w, 1.0)).xyz;
    // Do not paint rear limbs, pouches or inner surfaces over this model itself.
    if (all(greaterThanEqual(blocker,bounds_min)) && all(lessThanEqual(blocker,bounds_max))) { discard; }
    if (target_distance <= scene_distance + 0.04) { discard; }
    ALBEDO = team_color.rgb;
    ALPHA = 0.68;
}
"""
	var material=ShaderMaterial.new();material.shader=shader;material.render_priority=120
	material.set_shader_parameter("team_color",Color("48baff") if team==0 else Color("ff983e"))
	material.set_shader_parameter("bounds_min",bounds.position);material.set_shader_parameter("bounds_max",bounds.end)
	materials[key]=material;return material
static func apply(node:Node3D,device:Dictionary,local_id:int):
	if node.get_meta("upgrade_selected",false):return
	var owned=local_id>0 and int(device.owner)==local_id
	var key="%s:%s:%s"%[owned,device.team,device.get("level",1)]
	var changed=node.get_meta("silhouette_state","")!=key
	if changed:
		node.set_meta("silhouette_state",key)
		node.set_meta("silhouette_meshes",node.find_children("*","MeshInstance3D",true,false))
	var meshes=node.get_meta("silhouette_meshes",[])
	if not owned:
		if changed:
			for mesh in meshes:mesh.material_overlay=null
		return
	# Union the whole assembly in root space, then express it in each mesh space.
	# A per-part box mistakes a neighbouring part for a wall.
	var bounds=AABB();var first=true
	for mesh in meshes:
		var relative=node.global_transform.affine_inverse()*mesh.global_transform
		var part=relative*mesh.get_aabb()
		bounds=part if first else bounds.merge(part);first=false
	for mesh in meshes:
		var relative=mesh.global_transform.affine_inverse()*node.global_transform
		var local_bounds=relative*bounds.grow(.06)
		if changed:mesh.material_overlay=material_for(int(device.team),AABB()).duplicate()
		mesh.material_overlay.set_shader_parameter("bounds_min",local_bounds.position)
		mesh.material_overlay.set_shader_parameter("bounds_max",local_bounds.end)
