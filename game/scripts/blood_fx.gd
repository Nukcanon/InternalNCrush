extends Node3D
class_name BloodFX
var drops:Array=[]
var marks:Array=[]
var shader:Shader
const MAX_DROPS=64
const MAX_MARKS=48
func emit_hit(point:Vector3,direction:Vector3,amount:float):
	var rng=RandomNumberGenerator.new();rng.randomize()
	for i in range(clampi(5+int(amount/12.),5,11)):
		if drops.size()>=MAX_DROPS:break
		var velocity=direction.normalized()*rng.randf_range(.7,2.6)+Vector3(rng.randf_range(-.8,.8),rng.randf_range(.2,1.5),rng.randf_range(-.8,.8))
		var node=MeshFactory.sphere(self,point,Vector3(.023,.025,.047)*rng.randf_range(.7,1.4),Color("9b2931"));node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		drops.append({"node":node,"velocity":velocity,"age":0.})
	# Projection follows actual surface normals, including nearby walls and slopes.
	for target in [point+direction.normalized()*2.5,point+Vector3.DOWN*5.]:
		var ray=PhysicsRayQueryParameters3D.create(point,target,1)
		var hit=get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():stain(hit.position,hit.normal,clampf(.14+amount*.002,.16,.34))
func stain(point:Vector3,normal:Vector3,radius:float):
	while marks.size()>=MAX_MARKS:
		var old=marks.pop_front()
		if is_instance_valid(old):old.queue_free()
	if shader==null:
		shader=Shader.new();shader.code="""
shader_type spatial;
render_mode cull_disabled, depth_draw_never;
uniform float fade=1.; uniform float seed=1.;
float hash(float p){return fract(sin(p*127.1)*43758.5453);}
void fragment(){
 vec2 p=(UV-.5)*2.;float a=atan(p.y,p.x);float edge=.64+.10*sin(a*5.+seed)+.065*sin(a*11.-seed);
 float mask=1.-smoothstep(edge-.025,edge+.025,length(p));
 for(int i=0;i<8;i++){float n=float(i)+seed;vec2 c=vec2(cos(n*2.4),sin(n*2.4))*(.65+hash(n)*.19);mask=max(mask,1.-smoothstep(.025,.055+hash(n+7.)*.035,length(p-c)));}
 if(mask<.015){discard;}
 ALBEDO=mix(vec3(.075,.009,.012),vec3(.25,.018,.028),clamp(.9-length(p)*.3,0.,1.));
 ROUGHNESS=.63;SPECULAR=.24;ALPHA=mask*fade*.83;
}
"""
	var mesh=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2.ONE*radius*2.;mesh.mesh=plane;add_child(mesh)
	mesh.position=point+normal*.013;mesh.quaternion=Quaternion(Vector3.UP,normal.normalized());mesh.rotate_object_local(Vector3.UP,randf()*TAU);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("seed",randf()*30.);material.set_shader_parameter("fade",1.);mesh.material_override=material;marks.append(mesh)
	var tween=mesh.create_tween();tween.tween_interval(20.);tween.tween_method(func(value):material.set_shader_parameter("fade",value),1.,0.,5.);tween.tween_callback(mesh.queue_free)
func _physics_process(dt:float):
	for drop in drops.duplicate():
		drop.age+=dt
		if not is_instance_valid(drop.node):drops.erase(drop);continue
		if drop.age>1.1:drop.node.queue_free();drops.erase(drop);continue
		drop.velocity.y-=9.8*dt;var previous=drop.node.position;var next=previous+drop.velocity*dt
		var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(previous,next,1))
		if not hit.is_empty():
			if drop.age>.1:stain(hit.position,hit.normal,.035)
			drop.node.queue_free();drops.erase(drop)
		else:drop.node.position=next
