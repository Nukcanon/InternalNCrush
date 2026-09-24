class_name WebRenderer
extends Node
## Compatibility renderer uses a real smaller render target, preserving native UI.
var scene:SubViewport
var camera:Camera3D
var output:TextureRect
var ceiling=540
var height=540
var elapsed=0.
var frames=0
var warmup=5.
func _ready():
	var window=get_tree().root
	ceiling=432 if TouchControls.supported() else 540;height=ceiling
	scene=SubViewport.new();scene.name="Web3D";scene.world_3d=window.world_3d
	scene.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	scene.msaa_3d=Viewport.MSAA_DISABLED;scene.positional_shadow_atlas_size=0
	add_child(scene);camera=Camera3D.new();scene.add_child(camera);camera.current=true
	var layer=CanvasLayer.new();layer.layer=-100;add_child(layer)
	output=TextureRect.new();output.mouse_filter=Control.MOUSE_FILTER_IGNORE
	output.texture=scene.get_texture();output.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	output.stretch_mode=TextureRect.STRETCH_SCALE;layer.add_child(output)
	window.disable_3d=true;window.size_changed.connect(resize);resize()
func resize():
	var size=get_tree().root.size
	var ratio=minf(1.,float(height)/maxi(1,size.y))
	scene.size=Vector2i(maxi(320,int(size.x*ratio)),maxi(180,int(size.y*ratio)))
	output.size=size
func _process(dt):
	var source=get_tree().root.get_camera_3d()
	if is_instance_valid(source):
		camera.global_transform=source.global_transform
		camera.fov=source.fov;camera.near=source.near;camera.far=source.far
		camera.projection=source.projection;camera.size=source.size
		camera.h_offset=source.h_offset;camera.v_offset=source.v_offset;camera.frustum_offset=source.frustum_offset
		camera.cull_mask=source.cull_mask;camera.keep_aspect=source.keep_aspect
		camera.environment=source.environment;camera.attributes=source.attributes
	# Hysteresis avoids resize oscillation; no gameplay/visibility range reduction.
	if warmup>0:warmup-=dt;return
	elapsed+=dt;frames+=1
	if elapsed<3.:return
	var fps=frames/elapsed;var old=height
	if fps<38:height=maxi(288,int(height*.8))
	elif fps>57:height=mini(ceiling,height+36)
	if old!=height:resize()
	elapsed=0.;frames=0
