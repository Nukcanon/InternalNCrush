class_name DeploymentPreview
extends Node3D
var game:Node
var ghost:Node3D
var arc:MeshInstance3D
var kind=""
var material:StandardMaterial3D
var timer=0.
func _process(dt:float):
	var p=game.players.get(game.local_id,{})
	var selected=str(p.get("placing","")) if p.get("alive",false) and not is_instance_valid(game.ui.panel) else ""
	visible=selected!=""
	if not visible:return
	if selected!=kind:
		kind=selected
		if is_instance_valid(ghost):ghost.queue_free()
		if is_instance_valid(arc):arc.queue_free()
		ghost=Node3D.new();add_child(ghost);CombatFX.device(ghost,kind,int(p.team));ghost.scale=Vector3.ONE*(.5 if kind=="turret" else 1.)
		material=CombatFX.glow(Color(.2,1.,.7,.3));material.no_depth_test=false
		for mesh in ghost.find_children("*","MeshInstance3D",true,false):mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arc=MeshInstance3D.new();add_child(arc);arc.material_override=material;arc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if kind=="turret":
			var lines=ImmediateMesh.new();lines.surface_begin(Mesh.PRIMITIVE_LINES)
			var radius=TurretLogic.range_for(game,1)
			var points=[]
			for i in range(49):points.append(Vector3(sin(lerpf(-TurretLogic.HALF_ARC,TurretLogic.HALF_ARC,i/48.)),0.,-cos(lerpf(-TurretLogic.HALF_ARC,TurretLogic.HALF_ARC,i/48.)))*radius+Vector3.UP*.07)
			for i in range(48):lines.surface_add_vertex(points[i]);lines.surface_add_vertex(points[i+1])
			for point in [points.front(),points.back()]:lines.surface_add_vertex(Vector3.UP*.07);lines.surface_add_vertex(point)
			lines.surface_end();arc.mesh=lines
		timer=0.
	timer-=dt
	if timer>0:return
	timer=.05
	var placement=Deployment.candidate(game,game.local_id,kind);position=placement.pos;rotation.y=placement.yaw
	material.albedo_color=Color(.16,1.,.65,.32) if placement.valid else Color(1.,.12,.08,.43)
