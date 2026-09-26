class_name TurretSelection
extends RefCounted
const RANGE=5.
const CONE=70.
static var outline:ShaderMaterial
static func remaining(g:Node,id:int) -> float:
	var p=g.players.get(id,{})
	if p.is_empty():return INF
	var value=maxf(0.,float(p.skill_ready)-g.clock)
	for d in g.devices.values():
		if d.kind=="turret" and int(d.owner)==id:value=maxf(value,float(d.get("upgrade_ready",0))-g.clock)
	return value
static func eligible(g:Node,id:int,did:int,check_clock:bool=true) -> bool:
	if not g.players.has(id) or not g.actors.has(id) or not g.devices.has(did):return false
	var p=g.players[id];var d=g.devices[did]
	if p.role!=3 or not g.options.skills or not g.options.classes or g.phase!="combat" or not g.can_attack(p):return false
	if (check_clock and remaining(g,id)>0.) or d.kind!="turret" or d.level>=4 or Construction.active(g,d) or float(d.get("upgrade_ready",0))>g.clock:return false
	if int(d.owner)!=id and (not g.players.has(int(d.owner)) or g.enemies(p,g.players[int(d.owner)])):return false
	var a=g.actors[id]
	if a.position.distance_to(d.pos)>=RANGE:return false
	var exclude=[a.get_rid()]
	if g.device_nodes.has(did):exclude.append(g.device_nodes[did].get_rid())
	return g.clear_line(a.eye(),d.pos+Vector3.UP*.6,exclude)
static func target(g:Node,id:int) -> int:
	var p=g.players.get(id,{})
	if p.is_empty() or p.get("placing","")!="" or MeleeCombat.active(p,g.clock) or remaining(g,id)>0.:return 0
	var best=INF;var found=0
	for did in g.devices:
		if not eligible(g,id,did,false):continue
		var a=g.actors[id];var d=g.devices[did]
		var delta=d.pos+Vector3.UP*.6-a.eye()
		var angle=acos(clampf(a.direction().dot(delta.normalized()),-1.,1.))
		if angle>deg_to_rad(CONE):continue
		# Angular proximity dominates; distance breaks near-equal aim candidates.
		var score=.75*angle/deg_to_rad(CONE)+.25*a.position.distance_to(d.pos)/RANGE
		if score<best or (is_equal_approx(score,best) and int(did)<found):best=score;found=int(did)
	return found
static func caption(g:Node,id:int,did:int,mobile:bool=false) -> String:
	if did==0:return ""
	var owner=int(g.devices[did].owner)
	var prefix="나의" if owner==id else str(g.players[owner].nick)+"의"
	return prefix+" 포탑 업그레이드 ("+("스킬 버튼" if mobile else "F키")+")"
static func apply(g:Node,node:Node3D,d:Dictionary,selected:bool):
	if not selected and not node.get_meta("upgrade_selected",false):return
	if outline==null:
		outline=ShaderMaterial.new();var shader=Shader.new()
		shader.code="shader_type spatial; render_mode unshaded, cull_front, depth_draw_never; void vertex(){VERTEX+=NORMAL*(0.045/max(length(MODEL_MATRIX[0].xyz),0.001));} void fragment(){ALBEDO=vec3(1.0);}"
		outline.shader=shader
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if not mesh.get_meta("construction_edge",false):mesh.material_overlay=outline if selected else null
	node.set_meta("upgrade_selected",selected)
	if not selected:
		node.set_meta("silhouette_state","");DeploymentSilhouette.apply(node,d,g.local_id)
