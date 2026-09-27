class_name TargetReveal
extends RefCounted
static var outlines={}
static func outline_for(team:int) -> ShaderMaterial:
	if outlines.has(team):return outlines[team]
	var material=ShaderMaterial.new();var shader=Shader.new()
	shader.code="""shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, shadows_disabled;
uniform vec4 team_color : source_color;
void vertex(){VERTEX+=NORMAL*0.055;}
void fragment(){ALBEDO=team_color.rgb;}
"""
	material.shader=shader;material.set_shader_parameter("team_color",Color("48baff") if team==0 else Color("ff983e"));outlines[team]=material;return material
static func observer_key(game:Node,id:int) -> String:
	return "player:"+str(id) if int(game.options.mode)==1 else "team:"+str(game.players[id].team)
static func mark(game:Node,target:int,source:int,seconds:float):
	var p=game.players[target]
	var marks:Dictionary=p.get("reveal_to",{})
	var key=observer_key(game,source);marks[key]=maxf(float(marks.get(key,0)),game.clock+seconds)
	p.reveal_to=marks;p.mark=maxf(float(p.get("mark",0)),game.clock+seconds)
static func visible_to(game:Node,target:int,observer:int) -> bool:
	if target==observer or not game.players.has(observer) or not game.players.has(target):return false
	var p=game.players[target]
	return p.alive and p.mark>game.clock and float(p.get("reveal_to",{}).get(observer_key(game,observer),0))>game.clock
static func apply(actor:Node,p:Dictionary):
	var shown=visible_to(actor.game,actor.pid,actor.game.local_id)
	DeploymentSilhouette.apply(actor.character,{"owner":actor.game.local_id if shown else 0,"team":p.team,"level":str([p.role,actor.shown_weapon])},actor.game.local_id)
	if shown and not actor.character.get_meta("medic_selected",false):
		for mesh in actor.character.get_meta("silhouette_meshes",[]):
			if mesh.material_overlay!=null:mesh.material_overlay.next_pass=outline_for(int(p.team))
