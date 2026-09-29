extends SceneTree
# Renders the cartoon style proposal next to the current look.
var out="res://../validation/style-proposal/"
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+name+".png")
func lineup(stage:Node3D,team:int,hero:bool,z:float=0.) -> Array:
	var nodes=[]
	for role in range(6):
		var holder=Node3D.new();stage.add_child(holder);holder.position=Vector3(-3.75+role*1.5,0,z+4.);holder.rotation.y=PI+.25*(role-2.5)*.4
		var weapon_kind=["rifle","sniper","launcher","shotgun","rifle","pistol"][role]
		if hero:
			var rig=HeroModel.build(role,team,true);holder.add_child(rig);CharacterVisual.add_clips(rig)
			var player:AnimationPlayer=rig.get_node("AnimationPlayer");player.play("idle");player.seek(.4,true)
			var gun=HeroWeapon.build(weapon_kind,HeroStyle.ROLE_ACCENT[role]);rig.get_node("Hips/Chest/WeaponSocket").add_child(gun);gun.scale=Vector3.ONE*.85
		else:
			var c=CharacterVisual.new();holder.add_child(c);c.build(role,team);c.animator.seek(.4,true)
		nodes.append(holder)
	return nodes
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1600,900);DisplayServer.window_set_size(Vector2i(1600,900))
	Catalog.load_all()
	var world=Node3D.new();root.add_child(world)
	HeroStage.environment(world);HeroStage.build(world)
	var cam=Camera3D.new();world.add_child(cam);cam.fov=55;cam.current=true
	var group=Node3D.new();world.add_child(group)
	lineup(group,0,true)
	cam.position=Vector3(0,1.7,9.6);cam.look_at(Vector3(0,1.1,4))
	await shot("1-heroes-blue")
	for n in group.get_children():n.free()
	lineup(group,1,true)
	await shot("2-heroes-orange")
	for n in group.get_children():n.free()
	lineup(group,0,false)
	await shot("0-current-blue")
	for n in group.get_children():n.free()
	# Weapons on a display row.
	var kinds=["pistol","rifle","shotgun","sniper","launcher"]
	for i in range(kinds.size()):
		var g=HeroWeapon.build(kinds[i],HeroStyle.ROLE_ACCENT[i]);group.add_child(g);g.position=Vector3(.15 if kinds[i]=="pistol" else 0,2.35-i*.34,4);g.rotation=Vector3(0,PI/2,0);g.scale=Vector3.ONE*1.1
	cam.position=Vector3(0,1.65,5.9);cam.look_at(Vector3(0,1.65,4))
	await shot("3-weapons")
	for n in group.get_children():n.free()
	# Map district sample from player height.
	lineup(group,1,true,-4)
	cam.position=Vector3(-3,1.6,9);cam.look_at(Vector3(1,1.1,-3))
	await shot("4-district")
	# Close-up portrait for face/readability.
	for n in group.get_children():n.free()
	for role in [1,2,5]:
		var h=Node3D.new();group.add_child(h);h.position=Vector3(-1.1+[1,2,5].find(role)*1.1,0,0);h.rotation.y=PI
		var rig=HeroModel.build(role,[0,1,0][[1,2,5].find(role)],true);h.add_child(rig);CharacterVisual.add_clips(rig);rig.get_node("AnimationPlayer").play("idle")
	cam.position=Vector3(0,1.62,2.6);cam.look_at(Vector3(0,1.45,0))
	await shot("5-portraits")
	quit(0)
