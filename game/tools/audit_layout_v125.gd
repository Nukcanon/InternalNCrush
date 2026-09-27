extends SceneTree
func _initialize():call_deferred("run")
func run():
	var report=[];var failures=0
	for index in range(31):
		var arena=Arena.new();root.add_child(arena);arena.build(index)
		var nav=BotNavigation.new();nav.build(arena);var routes=[]
		for team in range(2):
			for site in arena.sites:
				var path=nav.route(arena.spawn_points[team][0],site)
				var ok=path.size()>1 and path[-1].distance_to(site)<2.1
				if not ok:failures+=1
				routes.append({"team":team,"site":str(site),"reachable":ok,"points":path.size()})
		var item={"map":index,"name":Rules.MAPS[index],"partitions":arena.get_meta("room_partitions",0),"routes":routes,"chunks":arena.chunk_count}
		if DefusalLayout.enabled(index):item.junctions=DefusalLayout.spec(index).points.size()
		report.append(item);print("LAYOUT_AUDIT ",JSON.stringify(item));arena.free();await process_frame
	FileAccess.open("res://../validation/v125/layout-audit.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("LAYOUT_AUDIT_FAILURES ",failures);quit(1 if failures else 0)
