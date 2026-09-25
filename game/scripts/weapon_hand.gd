class_name WeaponHand
extends Node3D
## Original articulated first-person hand. Continuous finger surfaces bend at three
## anatomical joints; all flexion is constrained to the palm side (no hyperextension).
var fingers:Array=[]
var materials:Array=[]
var support=false
var pistol=false
var handed_mesh:Node3D
var contact_state:Array=[]
var last_pose=Vector2.INF
var skin=Color("bc947c")
static var finger_shader:Shader
const HAND_SCALE=1.32
const SUPPORT_SCALE=1.45
const ARM_THICKNESS=2.86 # Gentle increase; the wrist receives the larger change.

func build(is_support:bool,is_pistol:bool,role:int):
	support=is_support;pistol=is_pistol
	skin=HumanModel.SKIN_COLORS[role]
	var fabric=Color("45554e")
	HumanModel.loft(self,Vector3.ZERO,[Vector4(-.041,.032,.014,0),Vector4(-.025,.041,.016,0),Vector4(.005,.038,.015,0),Vector4(.030,.034,.024,.001),Vector4(.048,.036,.027,.002)],skin,8)
	# A fitted back-of-hand panel and a flat wrist cuff, without inflated capsule ends.
	HumanModel.loft(self,Vector3(0,.018,.006),[Vector4(-.042,.028,.010,0),Vector4(-.02,.034,.012,0),Vector4(.012,.025,.010,0)],fabric,8)
	HumanModel.loft(self,Vector3(0,.050,0),[Vector4(-.013,.036,.027,0),Vector4(.003,.037,.028,0),Vector4(.015,.037,.028,0)],fabric,8)
	for mesh in get_children():
		if mesh is MeshInstance3D:
			var is_skin=mesh.material_override.albedo_color==skin
			mesh.material_override=SurfaceFinish.hand_material(skin if is_skin else fabric,0 if is_skin else 2)
	if finger_shader==null:
		finger_shader=Shader.new();finger_shader.code="""
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 tint : source_color;
uniform vec3 curl;
uniform vec3 lengths;
uniform mat4 hand_to_weapon = mat4(1.0);
uniform mat4 weapon_to_hand = mat4(1.0);
uniform int contact_count = 0;
uniform vec3 contact_min[3];
uniform vec3 contact_max[3];
vec3 outside_contact(vec3 p, vec3 lo, vec3 hi) {
 if(all(greaterThan(p,lo)) && all(lessThan(p,hi))) {
  vec3 low=p-lo, high=hi-p;
  float d=min(min(low.x,low.y),min(low.z,min(high.x,min(high.y,high.z))));
  if(d==low.x)p.x=lo.x; else if(d==high.x)p.x=hi.x;
  else if(d==low.y)p.y=lo.y; else if(d==high.y)p.y=hi.y;
  else if(d==low.z)p.z=lo.z; else p.z=hi.z;
 }
 return p;
}
varying vec3 paint_normal;
mat3 bend(float angle) { float c=cos(angle),s=sin(angle);return mat3(vec3(1,0,0),vec3(0,c,s),vec3(0,-s,c)); }
void vertex() {
 float original_y=VERTEX.y;
 if(original_y < -lengths.x-lengths.y) { vec3 pivot=vec3(0,-lengths.x-lengths.y,0);mat3 r=bend(curl.z);VERTEX=pivot+r*(VERTEX-pivot);NORMAL=r*NORMAL; }
 if(original_y < -lengths.x) { vec3 pivot=vec3(0,-lengths.x,0);mat3 r=bend(curl.y);VERTEX=pivot+r*(VERTEX-pivot);NORMAL=r*NORMAL; }
 mat3 r=bend(curl.x);VERTEX=r*VERTEX;NORMAL=r*NORMAL;
 // A geometric grip constraint keeps bent fingertips outside the receiver,
 // grip and moving magazine. It does not change the weapon or gameplay shape.
 vec3 p=(hand_to_weapon*vec4(VERTEX,1.0)).xyz;
 for(int i=0;i<3;i++){if(i<contact_count)p=outside_contact(p,contact_min[i],contact_max[i]);}
 VERTEX=(weapon_to_hand*vec4(p,1.0)).xyz;
 paint_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
 float light=dot(normalize(paint_normal),normalize(vec3(.35,.85,.4)));
 float band=light<.05?.52:(light<.58?.76:1.0);
 float ink=smoothstep(.08,.20,abs(dot(normalize(NORMAL),normalize(VIEW))));
 ALBEDO=tint.rgb*mix(.2,band,ink);
}
"""
	for index in range(5):
		var finger=Node3D.new();finger.name="Finger"+str(index);add_child(finger)
		var lengths=Vector3(.033,.022,.017)*[.97,1.06,1.,.80,1.][index]
		finger.position=Vector3((index-1.5)*.019,-.035,0)
		if index==4:
			finger.position=Vector3(.036,.014,-.006);finger.rotation=Vector3(.22,0,-.82);lengths=Vector3(.030,.021,.016)
		var radius=.0085 if index<3 else .0074 if index==3 else .010
		var length=lengths.x+lengths.y+lengths.z
		var mesh=HumanModel.loft(finger,Vector3.ZERO,[Vector4(-length,.001,.001,0),Vector4(-length+.005,radius*.78,radius*.66,0),Vector4(-lengths.x-lengths.y,radius*.83,radius*.74,0),Vector4(-lengths.x,radius*.94,radius*.83,0),Vector4(-.007,radius,radius*.87,0),Vector4(.002,radius*.9,radius*.8,0)],skin,6)
		var material=ShaderMaterial.new();material.shader=finger_shader;material.set_shader_parameter("tint",skin);material.set_shader_parameter("lengths",lengths);mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Nail sits on the dorsal tip and uses the same joint deformation as its finger.
		var nail=HumanModel.loft(finger,Vector3.ZERO,[Vector4(-length+.003,radius*.32,.0012,radius*.64),Vector4(-length+.010,radius*.65,.0014,radius*.72),Vector4(-length+.016,radius*.45,.001,radius*.72)],skin.lightened(.12),6)
		var nail_material=material.duplicate();nail_material.set_shader_parameter("tint",skin.lightened(.12));nail.material_override=nail_material;nail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fingers.append(finger);materials.append([material,nail_material])
	# Reflect the anatomical mesh once, independently of wrist orientation.
	# Actor handedness mirrors both complete arms later for left-handed players.
	handed_mesh=Node3D.new();handed_mesh.name="AnatomicalHand"
	var geometry=get_children();add_child(handed_mesh)
	for node in geometry:remove_child(node);handed_mesh.add_child(node)
	handed_mesh.scale.x=-1. if support else 1.
	pose(0.,0.)

func pose(release:float,trigger:float):
	var state=Vector2(release,trigger)
	if state.is_equal_approx(last_pose):return
	last_pose=state
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
	HumanModel.loft(arm,Vector3.ZERO,[Vector4(0.,.063,.056,0),Vector4(.065,.068,.058,.005),Vector4(.15,.057,.047,.006),Vector4(.23,.041,.032,.003),Vector4(.29,.029,.023,0),Vector4(.32,.026,.021,0)],fabric,10)
	HumanModel.loft(arm,Vector3.ZERO,[Vector4(.28,.030,.025,0),Vector4(.307,.031,.026,0),Vector4(.326,.027,.022,0)],fabric.darkened(.14),8)
	for mesh in arm.get_children():
		if mesh is MeshInstance3D:mesh.material_override=SurfaceFinish.hand_material(fabric,1)
	return arm

static func align_wrist(rig:Node3D,palm:Vector3,elbow:Vector3,palm_normal:Vector3) -> Vector3:
	# +Y runs from the palm into the wrist; -Z is the flexion/palm side.
	# Preserve this anatomical axis instead of turning the whole hand by 90 degrees.
	var y=(elbow-palm).normalized()
	var z=-(palm_normal-y*palm_normal.dot(y)).normalized()
	var x=y.cross(z).normalized();z=x.cross(y).normalized()
	var size=HAND_SCALE*(SUPPORT_SCALE if rig.support else 1.)
	rig.basis=rig.get_parent().basis.inverse()*Basis(x,y,z).scaled(Vector3.ONE*size)
	return palm+y*(.058*size)

static func fit_forearm(arm:Node3D,elbow:Vector3,wrist:Vector3):
	var direction=wrist-elbow
	arm.position=elbow;arm.quaternion=Quaternion(Vector3.UP,direction.normalized());arm.scale=Vector3(ARM_THICKNESS,direction.length()/.32,ARM_THICKNESS)

func constrain_contacts(rig_to_weapon:Transform3D,boxes:Array):
	var state=[rig_to_weapon,boxes]
	if state==contact_state:return
	contact_state=state.duplicate(true)
	var minima=PackedVector3Array();var maxima=PackedVector3Array()
	for box in boxes:minima.append(box.position-Vector3.ONE*.002);maxima.append(box.end+Vector3.ONE*.002)
	for index in range(fingers.size()):
		var transform=rig_to_weapon*handed_mesh.transform*fingers[index].transform
		for material in materials[index]:
			material.set_shader_parameter("hand_to_weapon",transform)
			material.set_shader_parameter("weapon_to_hand",transform.affine_inverse())
			material.set_shader_parameter("contact_count",boxes.size())
			material.set_shader_parameter("contact_min",minima)
			material.set_shader_parameter("contact_max",maxima)
