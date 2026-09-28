class_name DistrictSetdressing
extends RefCounted
## Small, non-colliding tabletop items only. The supporting cover is identical
## in both exports; the Web budget removes no cover or traversal obstacle.
static var groups={}
static func decorate(parent:Node3D,kind:String,index:int,ordinal:int):
	if kind not in ["writing_desk","folding_table","console_table","picnic_table","round_cafe_table"]:return
	if groups.is_empty():
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/setdress_original/manifest.json"))
		for entry in data.assets:
			if not groups.has(entry.theme):groups[entry.theme]=[]
			groups[entry.theme].append(entry.name)
	var themes=["retail","packaged_food","bakery","kitchen","produce"]
	if index in [0,1,5,21,23,28]:themes=["harbour","mechanics","utility","containers"]
	elif index in [2,8,11,13,15,18,25]:themes=["workshop","electrical","construction","mechanics","cleaning"]
	elif index in [3,14,20,29]:themes=["laboratory","medical","office","electrical"]
	elif index in [10,26]:themes=["garden","utility","sport"]
	elif index in [6,16,22,27]:themes=["paper","office","signage","cleaning"]
	var theme=themes[ordinal%themes.size()];var roster=groups[theme]
	var count=2 if RenderStyle.web() else 4
	var group=Node3D.new();parent.add_child(group);group.name="TabletopDetails"
	var used=[]
	for j in range(count):
		var item=Node3D.new();group.add_child(item)
		var asset=roster[(index*7+ordinal*3+j)%roster.size()]
		used.append(asset)
		ImportedWorldProp.build(item,asset,Vector3(.26,.35,.25),"setdress_original")
		item.position=Vector3((j%2-.5)*.52,.88,(j/2-.5)*.30)
		item.set_meta("setdress_asset",asset)
	# One shared vertex-colour mesh per tabletop, not one draw per tiny object.
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for item in group.get_children():
		for mesh in item.get_children():
			if mesh is MeshInstance3D:
				for surface in range(mesh.mesh.get_surface_count()):st.append_from(mesh.mesh,surface,item.transform*mesh.transform)
		item.free()
	st.index();var visual=MeshInstance3D.new();visual.mesh=st.commit();visual.material_override=WorldSurface.material("detail",index,true)
	visual.set_meta("district_detail",true);visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;group.add_child(visual)
	group.set_meta("setdress_assets",used)
