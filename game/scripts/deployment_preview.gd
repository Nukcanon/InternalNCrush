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
		for old in [ghost,arc,fan,range_label]:
			if is_instance_valid(old):old.queue_free()
		ghost=Node3D.new();add_child(ghost);CombatFX.device(ghost,kind,int(p.team));ghost.scale=Vector3.ONE*(.5 if kind=="turret" else 1.)
		material=CombatFX.glow(Color(.2,1.,.7,.3));material.no_depth_test=false
		for mesh in ghost.find_children("*","MeshInstance3D",true,false):mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arc=MeshInstance3D.new();add_child(arc);arc.material_override=material;arc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if kind=="turret":range_view()
		timer=0.
	timer-=dt
	if timer>0:return
	timer=.05
	var placement=Deployment.candidate(game,game.local_id,kind);position=placement.pos;basis=Deployment.basis_on_ground(game,placement.pos,placement.yaw,kind)
	material.albedo_color=Color(.16,1.,.65,.32) if placement.valid else Color(1.,.12,.08,.43)
	if is_instance_valid(arc) and arc.material_override!=material:arc.material_override.albedo_color=Color(.3,1.,.75,.7) if placement.valid else Color(1.,.25,.15,.7)
	if is_instance_valid(fan):fan.material_override.albedo_color=Color(.16,1.,.65,.13) if placement.valid else Color(1.,.2,.1,.13)
# 1.4.2 turret attack range: the level-1 fan filled on the ground, its edge
# drawn through walls, dashed arcs for levels 2-4 and the distances written at
# the far edge (the turret fires only inside this 100-degree fan).
var fan:MeshInstance3D
var range_label:Label3D
func range_view():
	var radius=TurretLogic.range_for(game,1);var steps=64
	var at=func(angle:float,r:float) -> Vector3:return Vector3(sin(angle),0.,-cos(angle))*r+Vector3.UP*.07
	var fill=ImmediateMesh.new();fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(steps):
		var a0=lerpf(-TurretLogic.HALF_ARC,TurretLogic.HALF_ARC,float(i)/steps);var a1=lerpf(-TurretLogic.HALF_ARC,TurretLogic.HALF_ARC,float(i+1)/steps)
		for point in [Vector3.UP*.07,at.call(a0,radius),at.call(a1,radius)]:fill.surface_add_vertex(point)
	fill.surface_end()
	fan=MeshInstance3D.new();fan.mesh=fill;add_child(fan);fan.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fill_material=StandardMaterial3D.new();fill_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;fill_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;fill_material.cull_mode=BaseMaterial3D.CULL_DISABLED;fill_material.albedo_color=Color(.16,1.,.65,.13)
	fan.material_override=fill_material
	var lines=ImmediateMesh.new();lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for level in range(1,5):
		var r=TurretLogic.range_for(game,level)
		for i in range(steps):
			if level>1 and i%2==1:continue # dashed upgrade ranges
			lines.surface_add_vertex(at.call(lerpf(-TurretLogic.HALF_ARC,TurretLogic.HALF_ARC,float(i)/steps),r));lines.surface_add_vertex(at.call(lerpf(-TurretLogic.HALF_ARC,TurretLogic.HALF_ARC,float(i+1)/steps),r))
	for side in [-1.,1.]:lines.surface_add_vertex(Vector3.UP*.07);lines.surface_add_vertex(at.call(side*TurretLogic.HALF_ARC,TurretLogic.range_for(game,4)))
	lines.surface_end();arc.mesh=lines
	var edge=material.duplicate();edge.no_depth_test=true;arc.material_override=edge
	range_label=Label3D.new();add_child(range_label);range_label.position=at.call(0.,radius)+Vector3.UP*1.2
	range_label.text="사거리 %d m\n강화 시 %d · %d · %d m"%[roundi(radius),roundi(TurretLogic.range_for(game,2)),roundi(TurretLogic.range_for(game,3)),roundi(TurretLogic.range_for(game,4))]
	range_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;range_label.no_depth_test=true;range_label.fixed_size=true;range_label.pixel_size=.0012;range_label.font_size=34;range_label.outline_size=10;range_label.modulate=Color(.75,1.,.9);range_label.outline_modulate=Color("0c2019")
	if is_instance_valid(game.ui) and game.ui.theme:range_label.font=game.ui.theme.default_font
