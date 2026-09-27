extends Node3D
class_name PracticalLights
## Four reusable light slots, independent of the map's fixture count.
@export var fixtures:Array=[]
var pool:Array[SpotLight3D]=[]
var elapsed=1.
func _process(delta:float):
	elapsed+=delta
	if elapsed<.20:return
	elapsed=0.
	var camera=get_viewport().get_camera_3d()
	if GraphicsOptions.lighting<2 or camera==null:
		for light in pool:light.visible=false
		return
	if pool.is_empty():
		for i in range(4):
			var light=SpotLight3D.new();light.name="NearbyFixture"+str(i);light.set_meta("pooled_practical",true)
			light.shadow_enabled=false;light.spot_angle=72.;light.spot_attenuation=1.2;add_child(light);pool.append(light)
	var nearby=[]
	for fixture in fixtures:
		var distance=camera.global_position.distance_squared_to(to_global(fixture.pos))
		if distance<400.:nearby.append({"fixture":fixture,"distance":distance})
	nearby.sort_custom(func(a,b):return a.distance<b.distance)
	for i in range(pool.size()):
		var light=pool[i];light.visible=i<nearby.size()
		if not light.visible:continue
		var fixture=nearby[i].fixture
		light.position=fixture.pos;light.look_at(to_global(fixture.pos+fixture.direction))
		light.light_color=fixture.color;light.spot_range=fixture.range
		light.light_energy=fixture.energy*clampf((20.-sqrt(nearby[i].distance))/6.,0.,1.)
