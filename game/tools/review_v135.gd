extends SceneTree
# Captures the 1.3.5 lobby screens: online lobby, quick join, LAN lobby, waiting room.
var g:Node
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/v135/"+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://../validation/v135")
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	for i in range(10):await process_frame
	var ui=g.ui
	g.internet.token="review";g.internet.endpoint="";g.profile.lobby_url="https://internal-n-crush-lobby.internal-n-crush-directory.workers.dev"
	ui.internet_menu(false)
	ui.internet_rooms=[]
	for i in range(6):ui.internet_rooms.append({"id":"r%d"%i,"name":["점심 내전","방과후 3반","주말 설치해체","거점 연습","아무나 오세요","고수만"][i],"mode":i%5,"map":13 if i%5!=4 else 19,"players":1+i,"capacity":8,"phase":"lobby","ping":20+i*15,"locked":i==5})
	ui.render_internet_rooms();ui.notice_label.text=""
	await shot("online-lobby")
	ui.panel.find_child("QuickJoin",true,false).pressed.emit()
	await shot("quick-join")
	ui.close_quick_join();g.internet.token=""
	ui.join_menu();g.stop_room_search()
	for i in range(5):g.rooms["192.168.0.%d"%(10+i)]={"name":"내부망 %d번 방"%(i+1),"count":1+i,"bots":7-(1+i),"max":8,"mode":Rules.MODES[i%5],"version":Rules.VERSION,"locked":i==2,"ping":3+i}
	ui.update_rooms()
	await shot("lan-lobby")
	g.rooms.clear();ui.menu()
	g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.max_players=8
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80)
	g.add_player(1,"Player9870","review_host",0);g.add_player(2,"친구","review_guest",1);g.add_player(3,"옆반","review_guest2",0);TeamBalance.reconcile(g)
	ui.lobby()
	await shot("waiting-room")
	quit(0)
