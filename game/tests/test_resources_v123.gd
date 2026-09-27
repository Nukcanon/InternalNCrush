extends SceneTree
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	if not ok:failures+=1;printerr("FAIL ",message)
func sample() -> Dictionary:
	return {"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))}
func run():
	var fx=CombatFX.new();root.add_child(fx)
	var stream=HealingStream.new();root.add_child(stream)
	var same_mesh=stream.mesh.mesh
	var samples=[]
	for batch in range(6):
		for frame in range(300):
			for shot in range(40):
				var x=float(frame*40+shot)*.013
				fx.beam(Vector3(x,1,0),Vector3(x+.17,2.,-12.-x*.01),shot%5==0)
			stream.draw_link(Vector3.ZERO,Vector3(sin(frame*.1)*3.,1.,-12.),1./60.,frame%2==0)
			if frame%30==0:await process_frame
		await process_frame;await process_frame
		var s=sample();s.tracers=fx.tracers.size();s.mesh_cache=MeshFactory.meshes.size();samples.append(s);print("RESOURCE_SAMPLE ",JSON.stringify(s))
		expect(fx.tracers.size()<=CombatFX.MAX_TRACERS,"tracer count bounded")
		expect(stream.mesh.mesh==same_mesh,"healing retains immutable mesh")
	for s in samples.slice(2):
		expect(s.objects<=samples[1].objects+8,"objects stop growing after warmup")
		expect(s.resources<=samples[1].resources+2,"resources stop growing after warmup")
		expect(s.nodes==samples[1].nodes,"node count constant")
	fx.clear();await process_frame;await process_frame
	expect(fx.get_child_count()==0 and fx.tracers.is_empty(),"clear releases pooled nodes")
	fx.free();stream.free();await process_frame
	print("RESOURCE_RESULT failures=",failures," shots=72000 healing_updates=1800");quit(1 if failures else 0)
