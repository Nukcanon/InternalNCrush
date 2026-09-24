class_name WeaponHand
extends Node3D
## Original articulated first-person hand. Continuous finger surfaces bend at three
## anatomical joints; all flexion is constrained to the palm side (no hyperextension).
var fingers:Array=[]
var materials:Array=[]
var support=false
var pistol=false
var skin=Color("bc947c")
static var finger_shader:Shader

func build(is_support:bool,is_pistol:bool,role:int):
	support=is_support;pistol=is_pistol
	skin=HumanModel.SKIN_COLORS[role]
	var fabric=Color("45554e")
	HumanModel.loft(self,Vector3.ZERO,[Vector4(-.041,.032,.014,0),Vector4(-.025,.041,.016,0),Vector4(.005,.038,.015,0),Vector4(.030,.029,.014,.001),Vector4(.048,.022,.013,.002)],skin,24)
	# A fitted back-of-hand panel and a flat wrist cuff, without inflated capsule ends.
	HumanModel.loft(self,Vector3(0,.018,.006),[Vector4(-.042,.028,.010,0),Vector4(-.02,.034,.012,0),Vector4(.012,.025,.010,0)],fabric,20)
	HumanModel.loft(self,Vector3(0,.050,0),[Vector4(-.013,.024,.016,0),Vector4(.003,.025,.017,0),Vector4(.015,.025,.017,0)],fabric,20)
	for mesh in get_children():
		if mesh is MeshInstance3D:
			var is_skin=mesh.material_override.albedo_color==skin
			mesh.material_override=SurfaceFinish.hand_material(skin if is_skin else fabric,0 if is_skin else 2)
	if finger_shader==null:
		finger_shader=Shader.new();finger_shader.code="""
shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color;
uniform vec3 curl;
uniform vec3 lengths;
uniform sampler2D operator_atlas:source_color,filter_linear_mipmap_anisotropic;
varying vec3 rest_position;
mat3 bend(float angle) { float c=cos(angle),s=sin(angle);return mat3(vec3(1,0,0),vec3(0,c,s),vec3(0,-s,c)); }
void vertex() {
 rest_position=VERTEX;
 float original_y=VERTEX.y;
 if(original_y < -lengths.x-lengths.y) { vec3 pivot=vec3(0,-lengths.x-lengths.y,0);mat3 r=bend(curl.z);VERTEX=pivot+r*(VERTEX-pivot);NORMAL=r*NORMAL; }
 if(original_y < -lengths.x) { vec3 pivot=vec3(0,-lengths.x,0);mat3 r=bend(curl.y);VERTEX=pivot+r*(VERTEX-pivot);NORMAL=r*NORMAL; }
 mat3 r=bend(curl.x);VERTEX=r*VERTEX;NORMAL=r*NORMAL;
}
void fragment() { vec3 tex=texture(operator_atlas,vec2(.003)+abs(fract(rest_position.xy*8.)*2.-1.)*.494).rgb;if(OUTPUT_IS_SRGB){tex=pow(tex,vec3(2.2));}float detail=clamp(dot(tex,vec3(.333))/.35,.6,1.5);ALBEDO=tint.rgb*mix(1.,detail,.28);ROUGHNESS=.72;SPECULAR=.2; }
"""
	for index in range(5):
		var finger=Node3D.new();finger.name="Finger"+str(index);add_child(finger)
		var lengths=Vector3(.033,.022,.017)*[.97,1.06,1.,.80,1.][index]
		finger.position=Vector3((index-1.5)*.019,-.035,0)
		if index==4:
			finger.position=Vector3(.036,.014,-.006);finger.rotation=Vector3(.22,0,-.82);lengths=Vector3(.030,.021,.016)
		var radius=.0085 if index<3 else .0074 if index==3 else .010
		var length=lengths.x+lengths.y+lengths.z
		var mesh=HumanModel.loft(finger,Vector3.ZERO,[Vector4(-length,.001,.001,0),Vector4(-length+.005,radius*.78,radius*.66,0),Vector4(-lengths.x-lengths.y,radius*.83,radius*.74,0),Vector4(-lengths.x,radius*.94,radius*.83,0),Vector4(-.007,radius,radius*.87,0),Vector4(.002,radius*.9,radius*.8,0)],skin,12)
		var material=ShaderMaterial.new();material.shader=finger_shader;material.set_shader_parameter("operator_atlas",load("res://assets/textures/operator_materials_v11.png"));material.set_shader_parameter("tint",skin);material.set_shader_parameter("lengths",lengths);mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Nail sits on the dorsal tip and uses the same joint deformation as its finger.
		var nail=HumanModel.loft(finger,Vector3.ZERO,[Vector4(-length+.003,radius*.32,.0012,radius*.64),Vector4(-length+.010,radius*.65,.0014,radius*.72),Vector4(-length+.016,radius*.45,.001,radius*.72)],skin.lightened(.12),10)
		var nail_material=material.duplicate();nail_material.set_shader_parameter("tint",skin.lightened(.12));nail.material_override=nail_material;nail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fingers.append(finger);materials.append([material,nail_material])
	pose(0.,0.)

func pose(release:float,trigger:float):
	var opened=clampf(release,0.,1.)
	for index in range(5):
		var curl=Vector3(.78,1.18,.58) if support else Vector3(.72,1.23,.66)
		if index==0 and not support:curl=Vector3(.25+.16*clampf(trigger,0.,1.),.66+.16*clampf(trigger,0.,1.),.30)
		if index==4:curl=Vector3(.30,.58,.28)
		curl=curl.lerp(Vector3(.10,.18,.08),opened*.82)
		curl=Vector3(clampf(curl.x,0.,1.35),clampf(curl.y,0.,1.65),clampf(curl.z,0.,1.2))
		fingers[index].set_meta("joint_flexion",curl)
		for material in materials[index]:material.set_shader_parameter("curl",curl)

static func forearm(parent:Node3D,role:int) -> Node3D:
	var arm=Node3D.new();parent.add_child(arm)
	var fabric=Color("68787c") if role!=5 else Color("aeb3a5")
	HumanModel.loft(arm,Vector3.ZERO,[Vector4(0.,.063,.056,0),Vector4(.065,.068,.058,.005),Vector4(.15,.057,.047,.006),Vector4(.23,.041,.032,.003),Vector4(.29,.029,.023,0),Vector4(.32,.026,.021,0)],fabric,28)
	HumanModel.loft(arm,Vector3.ZERO,[Vector4(.28,.030,.025,0),Vector4(.307,.031,.026,0),Vector4(.326,.027,.022,0)],fabric.darkened(.14),24)
	for mesh in arm.get_children():
		if mesh is MeshInstance3D:mesh.material_override=SurfaceFinish.hand_material(fabric,1)
	return arm

static func align_wrist(rig:Node3D,palm:Vector3,elbow:Vector3,palm_normal:Vector3) -> Vector3:
	# +Y runs from the palm into the wrist; -Z is the flexion/palm side.
	# Preserve this anatomical axis instead of turning the whole hand by 90 degrees.
	var y=(elbow-palm).normalized()
	var z=-(palm_normal-y*palm_normal.dot(y)).normalized()
	var x=y.cross(z).normalized();z=x.cross(y).normalized()
	rig.basis=rig.get_parent().basis.inverse()*Basis(x,y,z)
	return palm+y*.058

static func fit_forearm(arm:Node3D,elbow:Vector3,wrist:Vector3):
	var direction=wrist-elbow
	arm.position=elbow;arm.quaternion=Quaternion(Vector3.UP,direction.normalized());arm.scale=Vector3(1,direction.length()/.32,1)
