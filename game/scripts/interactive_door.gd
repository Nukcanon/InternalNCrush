extends Node3D
class_name InteractiveDoor
var door_id=0
var opened=false
var progress=0.
var leaves:Array=[]
var arena:Node
var indicator:MeshInstance3D
const WIDTH=2.3
var opening_width=WIDTH
static var leaf_shader:Shader
var leaf_materials:Array=[]
func build(owner_arena:Node,id:int,pos:Vector3,yaw:float,opening:float=WIDTH):
	opening_width=opening
	arena=owner_arena;door_id=id;position=pos;rotation.y=yaw;name="AccessDoor"+str(id)
	var metal=Color("354954");var paint=Color("3faaa4")
	if leaf_shader==null:
		leaf_shader=Shader.new();leaf_shader.code="""
shader_type spatial;
uniform float leaf_offset=0.;
uniform float leaf_mirror=1.;
uniform float half_aperture=1.15;
varying float aperture_x;
void vertex(){aperture_x=VERTEX.x*leaf_mirror+leaf_offset;}
void fragment(){
 if(abs(aperture_x)>half_aperture)discard;
 ALBEDO=COLOR.rgb;ROUGHNESS=clamp(UV2.x,.24,.96);METALLIC=clamp(UV2.y,0.,1.);
}
"""
	# 1.4.6: procedural leaves (DoorModels) matched to the buildings and region
	# around the door; one mesh shared by both leaves.
	var family=DoorModels.family_at(arena.map_index,pos,arena.bounds,arena.get_meta("plan_fronts",[]))
	var kit=DistrictFacade.Kit.new();DoorModels.leaf(kit,family,id+arena.map_index)
	var leaf_mesh=kit.detail.commit()
	set_meta("door_family",family)
	if family in ["wood_panel","ornate","plank","barn","shoji","frosted"]:metal=Color("4a3424") # timber frame for timber doors
	for side in [-1,1]:
		MeshFactory.box(self,Vector3(side*(opening_width*.5+.13),1.40,0),Vector3(.18,2.8,.36),metal)
		var leaf=AnimatableBody3D.new();leaf.collision_layer=1;leaf.collision_mask=0;leaf.sync_to_physics=false;leaf.set_meta("door_id",id);leaf.set_meta("door",self);leaf.position=Vector3(side*opening_width*.25,1.4,0);add_child(leaf)
		var holder=Node3D.new();leaf.add_child(holder);holder.position.y=-1.4
		var leaf_visual=MeshInstance3D.new();leaf_visual.mesh=leaf_mesh;holder.add_child(leaf_visual)
		holder.scale.x=-side*opening_width/WIDTH
		var material=ShaderMaterial.new();material.shader=leaf_shader;material.set_shader_parameter("leaf_offset",leaf.position.x);material.set_shader_parameter("leaf_mirror",holder.scale.x);material.set_shader_parameter("half_aperture",opening_width*.5)
		for mesh in holder.get_children():
			if mesh is MeshInstance3D:mesh.material_override=material
		leaf_materials.append(material)
		var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(opening_width*.5,2.8,.19);shape.shape=box;leaf.add_child(shape);leaves.append(leaf)
	MeshFactory.box(self,Vector3(0,2.78,0),Vector3(opening_width+.44,.22,.40),metal)
	indicator=MeshFactory.box(self,Vector3(0,2.8,-.23),Vector3(.66,.07,.035),Color("76edc8"));indicator.material_override=MeshFactory.material(Color("76edc8"))
func obstructed(actors:Dictionary) -> bool:
	for actor in actors.values():
		if not is_instance_valid(actor) or actor.collision_layer==0:continue
		var local=to_local(actor.global_position)
		if absf(local.x)<opening_width*.5+.42 and absf(local.z)<.72 and local.y>-.4 and local.y<2.7:return true
	return false
func toggle(actors:Dictionary) -> bool:
	if opened and obstructed(actors):return false
	opened=not opened;return true
func reset():opened=false;progress=0.;apply_pose()
func apply_pose():
	for i in range(leaves.size()):
		leaves[i].position.x=(i*2.-1.)*(opening_width*.25+progress*(opening_width*.5+.04))
		leaf_materials[i].set_shader_parameter("leaf_offset",leaves[i].position.x)
func _physics_process(dt:float):
	if arena.props_authoritative and not opened and progress>0.:
		var game=arena.get_parent()
		if game.get("actors") is Dictionary and obstructed(game.actors):opened=true
	progress=move_toward(progress,1. if opened else 0.,dt*1.35);apply_pose()
static func target(game:Node,id:int) -> InteractiveDoor:
	if not game.actors.has(id) or not is_instance_valid(game.arena):return null
	var actor=game.actors[id];var best:InteractiveDoor;var nearest=3.0
	for door in game.arena.doors.values():
		var point=door.global_position+Vector3.UP*1.3;var delta=point-actor.eye();var distance=delta.length()
		if distance>nearest or actor.direction().dot(delta.normalized())<.35:continue
		var hit=game.ray(actor.eye(),point,[actor.get_rid()],1|4|8)
		if not hit.is_empty() and hit.collider.get_meta("door_id",-1)!=door.door_id:continue
		best=door;nearest=distance
	return best
