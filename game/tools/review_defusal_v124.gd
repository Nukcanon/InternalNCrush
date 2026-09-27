extends SceneTree
func _initialize():call_deferred("run")
func capture(file:String):
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../validation/v124/"+file+".png")
func run():
 var g=load("res://scripts/game.gd").new();root.add_child(g)
 g.profile.menu_animation=false;g.profile.display_mode=0;g.profile.width=1280;g.profile.height=720;g.apply_display_settings()
 g.options.map=19;g.options.map_random=false;g.options.mode=4;g.options.bots=7;g.options.max_players=8
 g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.set_physics_process(false)
 await process_frame;await process_frame
 g.players[1].team=MatchFlow.attackers(g);g.players[1].cash=4200;g.bomb.carrier=1;g.ui.gear();g.ui.preview_kind=1;g.ui.gear_primary.select(1);g.ui.refresh_gear_detail()
 await capture("economy-native-720")
 g.phase="combat";g.bomb.buy_until=g.clock+60.;g.ui.show_hud();g.actors[1].position=Vector3.ZERO;g.ui.refresh()
 await capture("bomb-carrier-hud-720")
 g.actors[1].position=g.arena.sites[0];g.ui.refresh()
 await capture("bomb-plant-hud-720")
 g.ui.clear_panel();g.leave_game();g.queue_free();await process_frame;quit()
