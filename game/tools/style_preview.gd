extends SceneTree
# Renders the cartoon style proposal next to the current look.
var out="res://../validation/style-proposal/"
func _initialize():call_deferred("run")
var rigs=[]
func hero(parent:Node3D,role:int,team:int) -> Node3D:
	var rig=HeroSkin.pose_rig(role);parent.add_child(rig);CharacterVisual.add_clips(rig)
	var player:AnimationPlayer=rig.get_node("AnimationPlayer");player.play("idle");player.seek(.4,true)
	HeroSkin.install(rig,role,team,true);rigs.append(rig)
	return rig
func shot(name:String):
	for i in range(6):
		await process_frame
		for rig in rigs:
			if is_instance_valid(rig):OperatorSkin.sync(rig,rig.get_node("DeformSkeleton"))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+name+".png")
func lineup(stage:Node3D,team:int,hero:bool,z:float=0.) -> Array:
	var nodes=[]
	for role in range(6):
		var holder=Node3D.new();stage.add_child(holder);holder.position=Vector3(-3.75+role*1.5,0,z+4.);holder.rotation.y=PI+.25*(role-2.5)*.4
		var weapon_kind=["rifle","sniper","launcher","shotgun","rifle","pistol"][role]
		if hero:
			HeroStage.blob(holder)
			var rig=hero(holder,role,team)
			var gun=HeroWeapon.build(weapon_kind,HeroStyle.ROLE_ACCENT[role]);rig.get_node("Hips/Chest/WeaponSocket").add_child(gun);gun.scale=Vector3.ONE*.85
		else:
			var c=CharacterVisual.new();holder.add_child(c);c.build(role,team);c.animator.seek(.4,true)
		nodes.append(holder)
	return nodes
# Toon Shooter Game Kit (CC0) props, loaded straight from the source glTF for
# the proposal; the game build will bake them like the other prop libraries.
func prop(parent:Node3D,file:String,pos:Vector3,yaw:float=0.,size:float=1.):
	var doc=GLTFDocument.new();var state=GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path("res://").path_join("../../.tools/quaternius-toonshooter/env/"+file),state)!=OK:print("PROP_MISSING ",file);return
	var node:Node3D=doc.generate_scene(state);parent.add_child(node);node.position=pos;node.rotation.y=yaw;node.scale=Vector3.ONE*size
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		for s in range(mesh.mesh.get_surface_count()):
			var m=mesh.get_active_material(s)
			if m is BaseMaterial3D:mesh.set_surface_override_material(s,HeroStyle.tinted(m.albedo_color.lightened(.05),false,0.))
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1600,900);DisplayServer.window_set_size(Vector2i(1600,900))
	Catalog.load_all()
	var world=Node3D.new();root.add_child(world)
	HeroStage.environment(world);HeroStage.build(world)
	var kit=Node3D.new();world.add_child(kit)
	for spec in [["Barrier_Large.gltf",Vector3(-7.5,0,1.5),.2],["SackTrench.gltf",Vector3(6.5,0,1.8),PI],["Container_Small.gltf",Vector3(-11,0,-4),.4],["CardboardBoxes_2.gltf",Vector3(5,0,-2.5),.8],["ExplodingBarrel.gltf",Vector3(8.5,0,-1),0.],["StreetLight.gltf",Vector3(3.5,0,-8.5),0.],["TrafficCone.gltf",Vector3(-1.5,0,3.2),0.],["Pallet.gltf",Vector3(-4.5,0,-2.2),.5],["WaterTank_Floor.gltf",Vector3(12.5,0,-1.5),0.],["Crate.gltf",Vector3(-9.5,0,5),.3]]:
		prop(kit,spec[0],spec[1],spec[2])
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
		var g=HeroWeapon.build(kinds[i],HeroStyle.ROLE_ACCENT[i]);group.add_child(g);g.position=Vector3(.2 if kinds[i]=="pistol" else 0,2.5-i*.36,4);g.rotation=Vector3(0,PI/2+.55,.12);g.scale=Vector3.ONE*1.1
	cam.position=Vector3(0,1.78,5.95);cam.look_at(Vector3(0,1.78,4))
	await shot("3-weapons")
	for n in group.get_children():n.free()
	# Map district sample from player height.
	lineup(group,1,true,-4)
	cam.position=Vector3(-3,1.6,9);cam.look_at(Vector3(1,1.1,-3))
	await shot("4-district")
	# Close-up portrait for face/readability.
	for n in group.get_children():n.free()
	for role in [1,2,5]:
		var h=Node3D.new();group.add_child(h);h.position=Vector3(-1.1+[1,2,5].find(role)*1.1,0,5);h.rotation.y=PI
		hero(h,role,[0,1,0][[1,2,5].find(role)])
	cam.position=Vector3(0,1.62,7.6);cam.look_at(Vector3(0,1.4,5))
	await shot("5-portraits")
	quit(0)
