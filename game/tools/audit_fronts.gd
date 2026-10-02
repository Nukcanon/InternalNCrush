extends SceneTree
# 1.5.0 (the user: windows, bands and things on the side of a pillar where no
# wall stands): every facade front (plan fronts and the gate fronts) is probed
# along its length - just in front of it, a short ray back into the wall must
# hit something. Prints FRONT_FLOAT lines (map, place, flags) and a total.
# Args: map indices.
func _initialize():call_deferred("run")
func run():
	var maps=Array(OS.get_cmdline_user_args()).filter(func(x):return str(x).is_valid_int()).map(func(x):return int(x))
	if maps.is_empty():maps=range(31)
	Catalog.load_all()
	var total=0
	for index in maps:
		var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		for i in range(2):await physics_frame
		var space=arena.get_world_3d().direct_space_state
		var fronts:Array=arena.get_meta("facade_fronts",[])
		var floating=0;var shown=0
		for f in fronts:
			var u=Vector3(f[0],0,f[1]);var v=Vector3(f[2],0,f[3]);var length=u.distance_to(v)
			if length<.8:continue
			var d=(v-u)/length;var n=Vector3(-d.z,0,d.x) # out toward the street (DistrictFacade.build)
			var steps=maxi(2,int(length/.5));var bad=0;var first=Vector3.ZERO
			for k in range(1,steps):
				var t=float(k)/steps;var p=u.lerp(v,t)
				var y=lerpf(float(f[4]),float(f[5]),t)+float(f[6])+1.2
				var from=Vector3(p.x,y,p.z)+n*.25;var to=Vector3(p.x,y,p.z)-n*.3
				var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1|4|8))
				if hit.is_empty():
					bad+=1
					if bad==1:first=Vector3(p.x,y,p.z)
			if bad>=2:
				floating+=1
				if shown<12:print("FRONT_FLOAT map %d at %s flags %d length %.1f probes %d/%d"%[index,str(first.snapped(Vector3.ONE*.1)),int(f[9]),length,bad,steps-1]);shown+=1
		print("FRONTS map %d: %d fronts, %d floating"%[index,fronts.size(),floating]);total+=floating
		arena.queue_free();for i in range(3):await process_frame
	print("FRONT_FLOAT_TOTAL ",total);quit()
