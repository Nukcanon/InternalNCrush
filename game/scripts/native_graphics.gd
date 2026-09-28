class_name NativeGraphics
extends Node
## Automatic effect budgets, deliberately never changes output resolution.
var game:Node
var sampler=WebGraphics.new()
var level=1
var elapsed=0.
var frames=0
var warmup=8.
var context=""
func _exit_tree():sampler.free()
func reset():
	level=1;sampler.reset_auto();elapsed=0.;frames=0;warmup=8.
func _process(dt:float):
	if not is_instance_valid(game) or not game.profile.get("graphics_auto",false):return
	var next=str([game.options.map,game.phase])
	if next!=context:context=next;elapsed=0.;frames=0;warmup=8.
	if game.phase!="combat" or is_instance_valid(game.ui.panel) or not get_window().has_focus() or (is_instance_valid(game.kill_replay) and game.kill_replay.active):
		elapsed=0.;frames=0;return
	if not is_finite(dt) or dt<=0.:return
	if dt>1.:elapsed=0.;frames=0;warmup=2.;return
	if warmup>0.:warmup-=dt;return
	elapsed+=dt;frames+=1
	if elapsed<3.:return
	var fps=frames/elapsed;elapsed=0.;frames=0
	var cap=int(game.profile.get("frame_limit",60))
	if sampler.observe(fps,float(mini(cap,60) if cap>0 else 60)):
		level=sampler.level
		# Constant-time budgets; no scene-wide material rebuild mid-fight.
		GraphicsOptions.detail=level;GraphicsOptions.physics_effects=level
		GraphicsOptions.corpse_quality=level
		game.get_viewport().mesh_lod_threshold=[2.5,1.5,1.0][level]
