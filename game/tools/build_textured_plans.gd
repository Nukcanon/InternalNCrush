extends SceneTree
# Offline capture of the same map meshes/materials; no live second viewport in a match.
func _initialize():call_deferred("run")
func run():
	var destination="res://assets/arenas/plans"
	DirAccess.make_dir_recursive_absolute(destination)
	var viewport=SubViewport.new();viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=1000.;viewport.add_child(camera);camera.position=Vector3(0,400,0);camera.look_at(Vector3.ZERO,Vector3.FORWARD);camera.current=true
	var indices=range(32)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			indices=[]
			for entry in arg.trim_prefix("--maps=").split(","):indices.append(int(entry))
	for index in indices:
		var plan=DistrictLayout.read_plan(index);var dimensions=Vector2(plan.dimensions[0],plan.dimensions[1])
		viewport.size=Vector2i((dimensions/dimensions[dimensions.max_axis_index()]*1024.).round());camera.size=dimensions.y
		var container=Node3D.new();viewport.add_child(container);var meshes=[]
		for group in plan.groups:
			if group.kind not in ["ground","upper","lower","waterbed","water","roof","wall","perimeter","quay_edge","tunnel","stair_detail"]:continue
			var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(0,group.vertices.size(),3):
				var points=[]
				for j in range(3):var p=group.vertices[i+j];points.append(Vector3(p[0],p[1],p[2]))
				var normal=(points[2]-points[0]).cross(points[1]-points[0]).normalized()
				for point in points:st.set_normal(normal);st.add_vertex(point)
			st.index();var mesh=MeshInstance3D.new();mesh.mesh=st.commit();mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh.material_override=WorldSurface.material(group.kind,index,false,(1 if group.origin[0]>0 else 0)+(2 if group.origin[2]>0 else 0))
			mesh.set_meta("kind",group.kind);container.add_child(mesh);meshes.append(mesh)
		# The training range adds walkable galleries after the district layout.
		# Capture those actual surfaces as well, instead of showing the base map only.
		if index==PracticeLayout.INDEX:
			var arena=Arena.new();arena.bake_geometry=true;viewport.add_child(arena);arena.build(index);arena.hide()
			for surface in arena.walk_surfaces:
				var rect:Rect2=surface.rect
				var corners=[rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
				var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
				for corner in [0,1,2,0,2,3]:
					var point:Vector2=corners[corner]
					var fraction=clampf((point.y-rect.position.y)/maxf(.001,rect.size.y),0.,1.)
					st.set_normal(Vector3.UP);st.add_vertex(Vector3(point.x,lerpf(float(surface.low),float(surface.high),fraction)+.005,point.y))
				var mesh=MeshInstance3D.new();mesh.mesh=st.commit();mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mesh.material_override=WorldSurface.material("upper",index,false,0);mesh.set_meta("kind","upper");container.add_child(mesh);meshes.append(mesh)
			# Flush the temporary world's sky/render resources before disposing it.
			for frame in range(3):await process_frame
			arena.free()
		for level in range(3):
			for mesh in meshes:
				var kind=mesh.get_meta("kind")
				mesh.visible=kind in (["ground","roof","water","wall","perimeter","quay_edge","stair_detail"] if level==0 else ["upper","roof","wall","perimeter"] if level==1 else ["lower","waterbed","tunnel"])
			for frame in range(3):await process_frame
			await RenderingServer.frame_post_draw
			var picture=viewport.get_texture().get_image()
			picture.save_png(destination+"/map_%02d_%d.png"%[index,level])
			picture.resize(maxi(1,viewport.size.x/4),maxi(1,viewport.size.y/4),Image.INTERPOLATE_LANCZOS)
			picture.save_png(destination+"/map_%02d_%d_thumb.png"%[index,level])
		container.free();await process_frame;print("TEXTURED_PLAN ",index)
	viewport.free()
	for frame in range(4):await process_frame
	quit()
