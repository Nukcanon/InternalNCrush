extends SceneTree
var checks=0
var failures=0
class ManualGame extends Node:
	var profile={"web_quality":0}
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	expect(WebGraphics.quality({})==-1,"new and migrated browser profiles default to automatic")
	expect(WebGraphics.resolve({}).decor_quality==1,"automatic starts at a balanced medium profile")
	var policy=WebGraphics.new()
	expect(not policy.observe(20.,60.) and policy.level==1,"one slow sample window does not degrade quality")
	expect(policy.observe(20.,60.) and policy.level==0 and policy.scale_3d==1.,"sustained slow frames reduce effects before resolution")
	for i in range(6):expect(not policy.observe(60.,60.),"hold period prevents immediate quality oscillation")
	policy.observe(20.,60.);expect(policy.observe(20.,60.) and policy.scale_3d==.85,"resolution reduction occurs only after the lowest effect preset")
	for i in range(100):policy.observe(10.,60.)
	expect(policy.level==0 and policy.scale_3d==.85,"automatic never collapses resolution below 85 percent")
	for i in range(5):policy.observe(60.,60.)
	expect(policy.scale_3d==1. and policy.level==0,"sustained recovery restores sharpness before decorative detail")
	policy.reset_auto()
	for i in range(20):policy.observe(20. if i%2==0 else 60.,60.)
	expect(policy.level==1 and policy.scale_3d==1.,"alternating load does not make the view pump between presets")
	policy.reset_auto()
	for i in range(5):policy.observe(29.8,30.)
	expect(policy.level==2,"a selected 30 FPS cap is not mistaken for poor performance")
	var profile={"web_quality":3,"web_render_scale":.7,"web_options":{"lighting_quality":1,"shadow_quality":1,"antialias":2,"decor_quality":2,"fog_enabled":true},"graphics_quality":1,"physics_effects":2}
	var before=profile.duplicate(true);var settings=WebGraphics.resolve(profile)
	expect(settings.lighting_quality==1 and settings.shadow_quality==1 and settings.antialias==2 and settings.fog_enabled,"custom Web graphics preserve user choices")
	expect(settings.physics_effects==0 and profile==before,"browser cosmetic physics budget does not rewrite saved native settings")
	expect(WebGraphics.render_scale(profile)==.7 and WebGraphics.render_scale({"web_quality":-1},.1)==.85,"70 percent is an explicit manual choice, never an automatic result")
	var game=ManualGame.new();policy.game=game;policy.reset_auto()
	for i in range(100):policy._process(.1)
	expect(policy.level==1 and policy.scale_3d==1.,"manual mode bypasses the automatic controller")
	game.free();policy.free()
	print("WEB_GRAPHICS_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
