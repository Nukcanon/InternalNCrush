extends SceneTree
# 1.4 cartoon menu review: main menu, settings, bot battle setup, loadout,
# online lobby, quick join, waiting room and a confirmation dialog.
const OUT="res://../validation/ui-v14/"
var g:Node
func _initialize():call_deferred("run")
func shot(name:String,frames:=10):
	for i in range(frames):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1600,900);DisplayServer.window_set_size(root.size)
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(30):await process_frame
	var ui=g.ui
	ui.menu();await shot("01-main-menu",90)
	ui.host_settings();await shot("09-host-settings")
	ui.training_menu();await shot("10-training")
	ui.menu()
	ui.settings();await shot("02-settings")
	ui.practice_menu();await shot("03-bot-battle")
	ui.bot_setup=true;ui.bot_choice={"role":0,"primary":"a1","secondary":"pistol","armor_max":0,"gadget":0,"team":0};ui.gear();await shot("04-loadout",30)
	ui.bot_setup=false;ui.menu()
	g.internet.token="review";g.internet.endpoint="";g.profile.lobby_url="https://internal-n-crush-lobby.internal-n-crush-directory.workers.dev"
	ui.internet_menu(false);ui.internet_rooms=[]
	for i in range(6):ui.internet_rooms.append({"id":"r%d"%i,"name":["점심 내전","방과후 3반","주말 설치해체","거점 연습","아무나 오세요","고수만"][i],"mode":i%5,"map":13 if i%5!=4 else 19,"players":1+i,"capacity":8,"phase":"lobby","ping":20+i*15,"locked":i==5})
	ui.render_internet_rooms();ui.notice_label.text=""
	await shot("05-online-lobby")
	ui.panel.find_child("QuickJoin",true,false).pressed.emit();await shot("06-quick-join")
	ui.close_quick_join();g.internet.token="";ui.menu()
	g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.max_players=8
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80)
	g.add_player(1,"Player9870","review_host",0);g.add_player(2,"친구","review_guest",1);g.add_player(3,"옆반","review_guest2",0);TeamBalance.reconcile(g)
	ui.lobby();await shot("07-waiting-room")
	ui.confirm_room_leave();await shot("08-confirm")
	quit(0)
