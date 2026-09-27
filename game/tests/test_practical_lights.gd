extends SceneTree
func _initialize():call_deferred("run")
func run():
	var camera=Camera3D.new();root.add_child(camera);camera.current=true
	var lights=PracticalLights.new();root.add_child(lights)
	for i in range(100):lights.fixtures.append({"pos":Vector3(i*4,2,0),"direction":Vector3(0,-.4,1),"color":Color.WHITE,"range":7.,"energy":2.})
	GraphicsOptions.lighting=1;lights._process(1.);assert(lights.pool.is_empty(),"Medium does not allocate extra light slots")
	GraphicsOptions.lighting=2;lights._process(1.);assert(lights.pool.size()==4)
	assert(lights.pool[0].position.x==0.)
	camera.position.x=300.;lights._process(1.);assert(lights.pool[0].position.x==300.,"The four slots follow nearby fixtures, not map creation order")
	for light in lights.pool:assert(not light.shadow_enabled)
	GraphicsOptions.lighting=0;lights._process(1.)
	for light in lights.pool:assert(not light.visible)
	GraphicsOptions.lighting=2;camera.position.x=2000.;lights._process(1.)
	for light in lights.pool:assert(not light.visible)
	assert(lights.get_child_count()==4,"Travelling never accumulates light nodes")
	lights.free();camera.free();print("PRACTICAL_LIGHTS_PASS");quit()
