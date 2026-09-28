extends SceneTree
var failures=0
class Fixture extends Node:
	var arena:Node
	var options={"mode":4}
	var zone_owner=[-1,-1,-1]
func _initialize():call_deferred("run")
func run():
	for index in range(19,31):
		var g=Fixture.new();root.add_child(g);g.arena=Arena.new();g.add_child(g.arena);g.arena.build(index)
		var markers=ObjectiveMarkers.new();g.add_child(markers);markers.setup(g)
		for i in range(4):await physics_frame;await process_frame
		for entry in markers.entries:
			if entry.mesh.get_surface_count()==0:failures+=1;printerr("FAIL empty objective ring map=",index)
			else:
				var points=entry.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for p in points:
					if not p.is_finite():failures+=1;printerr("FAIL nonfinite marker")
		print("OBJECTIVE_FLOOR_MAP ",index," rings=",markers.entries.size())
		g.free();await process_frame
	print("OBJECTIVE_FLOOR_RESULT failures=",failures);quit(1 if failures else 0)
