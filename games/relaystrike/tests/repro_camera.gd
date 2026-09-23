extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scripts/game.gd").new();root.add_child(g);g.host_game();g.set_physics_process(false)
 g.add_player(-1,"Buddy","buddy");g.players[-1].team=g.players[1].team;g.actors[-1].position=Vector3(40,0,50)
 g.players[1].alive=false;g.spectator_target=-1;g.update_spectator();g.spawn(1);g.update_spectator()
 print("RESPAWN_CAMERA_LOCAL=",g.actors[1].camera.position)
 print("EYE_ERROR=",g.actors[1].camera.global_position.distance_to(g.actors[1].eye()))
 g.leave_game();g.queue_free();await process_frame;quit()
