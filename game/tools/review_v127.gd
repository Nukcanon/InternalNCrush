extends SceneTree
var camera:Camera3D
func _initialize():call_deferred("run")
func shot(name:String):
 for controller in root.find_children("NearbyLighting","",true,false):controller._process(1.)
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../validation/v127/"+name+".png")
func run():
 GraphicsOptions.shadows=0;GraphicsOptions.lighting=1;
 root.size=Vector2i(1280,720);DisplayServer.window_set_size(root.size);DirAccess.make_dir_recursive_absolute("res://../validation/v127")
 camera=Camera3D.new();root.add_child(camera);camera.current=true;camera.far=500.
 for index in [17,5,3,23]:
  var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
  var plan=DistrictLayout.read_plan(index);var f=plan.facades[0];var origin=Vector3(f[0],1.8,f[1]);var direction=Vector3(sin(f[2]),0,cos(f[2]))
  camera.position=origin+direction*8.;camera.look_at(origin);await shot("map-%02d-facade"%index)
  camera.position=arena.spawn_points[0][0]+Vector3(0,1.65,0);camera.look_at(arena.zones[0]+Vector3.UP*1.3);await shot("map-%02d-eye"%index)
  var elevated=arena.navigation_goals.filter(func(p):return p.y>4.)
  if not elevated.is_empty():
   var point:Vector3=elevated[0]
   camera.position=point+Vector3(0,-2.,4.);camera.look_at(point);await shot("map-%02d-underside"%index)
  var imports=arena.find_children("*","MeshInstance3D",true,false).filter(func(m):return m.has_meta("imported_world"))
  if not imports.is_empty():
   var box=imports[0].global_transform*imports[0].get_aabb();var center=box.get_center();camera.position=center+Vector3(4,2,5);camera.look_at(center);await shot("map-%02d-imported-prop"%index)
  GraphicsOptions.shadows=1;GraphicsOptions.lighting=2;GraphicsOptions.apply_world(arena)
  camera.position=origin+direction*8.;camera.look_at(origin);await shot("map-%02d-high-shadows"%index)
  if index==17:
   arena.get_node("Sun").light_energy=.05
   arena.get_node("Environment").environment.ambient_light_energy=.28
   camera.position=origin+direction*5.;camera.look_at(origin)
   GraphicsOptions.lighting=1;GraphicsOptions.apply_world(arena);await shot("market-lamps-off")
   GraphicsOptions.lighting=2;GraphicsOptions.apply_world(arena);await shot("market-lamps-on")
  GraphicsOptions.shadows=0;GraphicsOptions.lighting=1
  arena.free();await process_frame
 var viewer=MapViewer.new();root.add_child(viewer);viewer.theme=Theme.new();viewer.theme.default_font=load("res://assets/Korean.ttf");viewer.build([17]);await shot("map-viewer-close")
 var close=viewer.find_children("*","Button",true,false).filter(func(b):return b.text=="닫기")[0]
 assert(absf(close.global_position.x+close.size.x-(root.size.x-20))<3.,"Close stays at the far right of the map window")
 viewer.free();print("V127_RENDER_DONE");quit()
