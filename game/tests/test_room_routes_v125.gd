extends SceneTree
func _initialize():call_deferred("run")
func run():
 var failed=0
 var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.dedicated=true;g.server=true;g.phase="lobby"
 Engine.time_scale=4.
 for index in [10,13]:
  g.options.map_random=false;g.options.map=index;g.build_world()
  if not g.players.has(-1):g.add_player(-1,"ROOM WALK","room-check")
  var actor=g.actors[-1];var bot=BotAgent.new();bot.setup(g,-1);g.phase="combat"
  actor.position=g.arena.spawn_points[0][3];actor.velocity=Vector3.ZERO;actor.reset_view(0.);await physics_frame;await physics_frame
  DistrictLayout.route_spec(index)
  var spec=DistrictLayout.specs[index];var centers=[]
  for path in spec.paths:
   for p in path.slice(1,path.size()-1):
    var center=Vector2(p[0],p[1])-Vector2(spec.dimensions[0],spec.dimensions[1])*.5
    var pos=Vector3(center.x,0,center.y)
    if not centers.has(center) and g.arena.navigation_clear(pos) and absf(g.arena.walk_height(pos))<.05:centers.append(center)
  assert(centers.size()>=4,"Four distinct authored rooms must remain reachable")
  centers=centers.slice(0,4)
  for center in centers:
   var goal=Vector3(center.x,0,center.y)
   bot.path.clear();bot.next_path=0.;bot.goal=goal
   for tick in range(1800):
    var dt=Engine.time_scale/Engine.physics_ticks_per_second;g.clock+=dt;actor.input_state.x=0.;actor.input_state.z=0.;actor.input_state.sprint=false;bot.navigate(goal,dt);actor.simulate(dt,g.clock,true);await physics_frame
    if actor.position.distance_to(goal)<1.8:break
   var ok=actor.position.distance_to(goal)<1.8
   print("ROOM_WALK map=",index," goal=",goal," actual=",actor.position," ok=",ok)
   if not ok:failed+=1
 g.leave_game();g.free();await process_frame;print("ROOM_ROUTES_RESULT ",8-failed,"/8");quit(1 if failed else 0)
