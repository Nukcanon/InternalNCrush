extends RefCounted
class_name RoundCleanup
static func clear(g:Node):
	if g.server:
		for did in g.devices.keys():g.remove_device(did)
	else:g.devices.clear()
	for node in g.device_nodes.values():
		if is_instance_valid(node):node.queue_free()
	g.device_nodes.clear();g.fields.clear();g.grenades.clear();g.rockets.clear();g.drops.clear();g.heal_sound_times.clear();g.kill_events.clear()
	for node in g.drop_nodes.values():
		if is_instance_valid(node):node.queue_free()
	g.drop_nodes.clear()
	for mark in g.wall_marks:
		if is_instance_valid(mark):mark.queue_free()
	g.wall_marks.clear()
	if is_instance_valid(g.combat_fx):g.combat_fx.clear()
	if is_instance_valid(g.kill_replay):g.kill_replay.reset()
	if is_instance_valid(g.ui.damage_indicator):g.ui.damage_indicator.clear_hits()
