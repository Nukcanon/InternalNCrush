extends SceneTree
## Bakes the Toon Shooter Game Kit (CC0, Quaternius) guns into game-ready bases:
## muzzle toward -Z, +Y up, real-world length, butt (or pistol grip) at the
## origin, one surface per source material (recoloured per weapon at runtime),
## the magazine split out as its own node for reload animation, and markers:
## RightGrip / LeftGrip (wrist targets), Muzzle, Magazine.
##
## Marker coordinates are authored along the gun: u = 0 at the muzzle, 1 at the
## butt; v = 0 at the lowest point, 1 at the top; w = sideways (+ right).
const DIR="res://../../.tools/quaternius-toonshooter/guns/"
# length (m), muzzle v, right grip (u,v,w), left grip (u,v,w), magazine u-range, origin ("butt"|"grip")
const BASES={
	"AK":{"length":.86,"muzzle":.72,"right":Vector3(.70,.52,.06),"left":Vector3(.24,.60,-.05),"mag":Vector2(.30,.52),"origin":"butt"},
	"SMG":{"length":.58,"muzzle":.78,"right":Vector3(.70,.62,.06),"left":Vector3(.40,.40,-.05),"mag":Vector2(.30,.56),"origin":"butt"},
	"Pistol":{"length":.24,"muzzle":.80,"right":Vector3(.86,.62,.05),"left":Vector3(.80,.40,-.06),"mag":Vector2(.72,1.),"origin":"grip"},
	"Revolver":{"length":.32,"muzzle":.72,"right":Vector3(.86,.58,.05),"left":Vector3(.80,.38,-.06),"mag":Vector2(-1.,-1.),"origin":"grip"},
	"Revolver_Small":{"length":.25,"muzzle":.72,"right":Vector3(.86,.60,.05),"left":Vector3(.80,.40,-.06),"mag":Vector2(-1.,-1.),"origin":"grip"},
	"Shotgun":{"length":.98,"muzzle":.70,"right":Vector3(.60,.55,.06),"left":Vector3(.22,.40,-.05),"mag":Vector2(-1.,-1.),"origin":"butt"},
	"ShortCannon":{"length":.72,"muzzle":.62,"right":Vector3(.50,.55,.06),"left":Vector3(.22,.40,-.05),"mag":Vector2(-1.,-1.),"origin":"butt"},
	"Sniper":{"length":1.18,"muzzle":.66,"right":Vector3(.64,.50,.06),"left":Vector3(.38,.60,-.05),"mag":Vector2(.44,.62),"origin":"butt"},
	"Sniper_2":{"length":1.04,"muzzle":.62,"right":Vector3(.58,.50,.06),"left":Vector3(.30,.56,-.05),"mag":Vector2(.34,.52),"origin":"butt"},
	"RocketLauncher":{"length":1.05,"muzzle":.60,"right":Vector3(.36,.20,.06),"left":Vector3(.62,.30,-.08),"mag":Vector2(-1.,-1.),"origin":"butt"},
	"GrenadeLauncher":{"length":.74,"muzzle":.72,"right":Vector3(.80,.45,.06),"left":Vector3(.28,.30,-.05),"mag":Vector2(-1.,-1.),"origin":"butt"},
	"Knife_1":{"length":.30,"muzzle":.5,"right":Vector3(.85,.5,0),"left":Vector3(.85,.5,0),"mag":Vector2(-1.,-1.),"origin":"grip","vertical":true},
	"Shovel":{"length":.72,"muzzle":.5,"right":Vector3(.80,.5,0),"left":Vector3(.45,.5,0),"mag":Vector2(-1.,-1.),"origin":"grip","vertical":true},
	"Grenade":{"length":.11,"muzzle":.5,"right":Vector3(.5,.5,0),"left":Vector3(.5,.5,0),"mag":Vector2(-1.,-1.),"origin":"center","vertical":true},
	"FireGrenade":{"length":.14,"muzzle":.5,"right":Vector3(.5,.5,0),"left":Vector3(.5,.5,0),"mag":Vector2(-1.,-1.),"origin":"center","vertical":true}}
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/weapons")
	for base in BASES:bake(base,BASES[base])
	print("WEAPON_BAKE_OK");quit()
func bake(base:String,spec:Dictionary):
	var doc=GLTFDocument.new();var state=GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(DIR+base+".gltf"),state)!=OK:push_error("missing "+base);return
	var scene:Node3D=doc.generate_scene(state);root.add_child(scene)
	# Collect triangles per material in scene space.
	var by_material={};var names=[]
	for mesh_node in scene.find_children("*","MeshInstance3D",true,false):
		var xf:Transform3D=mesh_node.global_transform
		for s in range(mesh_node.mesh.get_surface_count()):
			var arrays=mesh_node.mesh.surface_get_arrays(s);var mat=mesh_node.mesh.surface_get_material(s)
			var name=mat.resource_name if mat else "Material";if not by_material.has(name):by_material[name]={"color":mat.albedo_color if mat is BaseMaterial3D else Color.WHITE,"v":PackedVector3Array(),"n":PackedVector3Array()};names.append(name)
			var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var n:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var idx=arrays[Mesh.ARRAY_INDEX]
			if idx==null or idx.is_empty():idx=range(v.size())
			for i in idx:by_material[name].v.append(xf*v[i]);by_material[name].n.append((xf.basis*n[i]).normalized())
	scene.queue_free()
	# Orientation: sources point the muzzle to -X (knives/shovel/grenades: +Y up).
	var vertical=bool(spec.get("vertical",false))
	var turn=Basis.IDENTITY if vertical else Basis(Vector3.UP,-PI/2)
	var lo=Vector3.INF;var hi=-Vector3.INF
	for name in names:
		for p in by_material[name].v:var q=turn*p;lo=lo.min(q);hi=hi.max(q)
	var size=hi-lo
	var along=size.y if vertical else size.z
	var scale=float(spec.length)/along
	# Normalised helpers (after turn): u from muzzle(-Z) to butt(+Z), v bottom->top.
	var point=func(u:float,v:float,w:float) -> Vector3:
		if vertical:return Vector3(lerpf(lo.x,hi.x,.5)+w*size.x,lerpf(hi.y,lo.y,u),lerpf(lo.z,hi.z,v))
		return Vector3(lerpf(lo.x,hi.x,.5)+w*size.x*4.,lerpf(lo.y,hi.y,v),lerpf(lo.z,hi.z,u))
	var origin:Vector3
	match str(spec.origin):
		"butt":origin=Vector3(lerpf(lo.x,hi.x,.5),lerpf(lo.y,hi.y,float(spec.muzzle)),hi.z)
		"grip":origin=point.call(spec.right.x,spec.right.y,0.)
		_:origin=(lo+hi)*.5
	var place=func(p:Vector3) -> Vector3:return (turn*p-origin)*scale
	var place_turned=func(q:Vector3) -> Vector3:return (q-origin)*scale
	# Magazine split: triangles whose centroid lies in the magazine u-range and the lower half.
	var mag_range:Vector2=spec.mag
	var root_node=Node3D.new();root_node.name=base
	var body=MeshInstance3D.new();body.name="Body";root_node.add_child(body);body.owner=root_node
	var mag_mesh=MeshInstance3D.new();mag_mesh.name="Magazine";root_node.add_child(mag_mesh);mag_mesh.owner=root_node
	var body_mesh=ArrayMesh.new();var mag_array=ArrayMesh.new()
	for name in names:
		var st_body=SurfaceTool.new();st_body.begin(Mesh.PRIMITIVE_TRIANGLES)
		var st_mag=SurfaceTool.new();st_mag.begin(Mesh.PRIMITIVE_TRIANGLES)
		var any_body=false;var any_mag=false
		var verts:PackedVector3Array=by_material[name].v;var norms:PackedVector3Array=by_material[name].n
		for t in range(0,verts.size(),3):
			var c=(turn*verts[t]+turn*verts[t+1]+turn*verts[t+2])/3.
			var u=inverse_lerp(lo.z,hi.z,c.z) if not vertical else 0.;var v=inverse_lerp(lo.y,hi.y,c.y)
			var in_mag=mag_range.x>=0. and u>=mag_range.x and u<=mag_range.y and v<.45
			var st=st_mag if in_mag else st_body
			if in_mag:any_mag=true
			else:any_body=true
			# Godot's glTF importer already converted the winding.
			for k in [0,1,2]:
				st.set_normal((turn*norms[t+k]).normalized());st.add_vertex(place.call(verts[t+k]))
		var mat=StandardMaterial3D.new();mat.resource_name=name;mat.albedo_color=by_material[name].color
		if any_body:st_body.set_material(mat);st_body.commit(body_mesh)
		if any_mag:st_mag.set_material(mat);st_mag.commit(mag_array)
	body.mesh=body_mesh
	if mag_array.get_surface_count()>0:mag_mesh.mesh=mag_array
	else:root_node.remove_child(mag_mesh);mag_mesh.free()
	for marker in [["RightGrip",spec.right],["LeftGrip",spec.left]]:
		var m=Marker3D.new();m.name=marker[0];root_node.add_child(m);m.owner=root_node
		m.position=place_turned.call(point.call(marker[1].x,marker[1].y,marker[1].z))
	var muzzle=Marker3D.new();muzzle.name="Muzzle";root_node.add_child(muzzle);muzzle.owner=root_node
	muzzle.position=place_turned.call(Vector3(lerpf(lo.x,hi.x,.5),lerpf(lo.y,hi.y,float(spec.muzzle)),lo.z)) if not vertical else place_turned.call(Vector3((lo.x+hi.x)*.5,hi.y,(lo.z+hi.z)*.5))
	if mag_range.x>=0.:
		var anchor=Marker3D.new();anchor.name="MagazineAnchor";root_node.add_child(anchor);anchor.owner=root_node
		anchor.position=place_turned.call(point.call((mag_range.x+mag_range.y)*.5,.45,0.))
	var packed=PackedScene.new();packed.pack(root_node)
	ResourceSaver.save(packed,"res://assets/weapons/"+base.to_lower()+".scn",ResourceSaver.FLAG_COMPRESS)
	print(base,": length ",spec.length," scale ",snappedf(scale,.001)," surfaces ",body_mesh.get_surface_count()," mag ",mag_array.get_surface_count())
	root_node.free()
