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
	"Sniper_2":{"length":1.04,"muzzle":.62,"right":Vector3(.58,.50,.06),"left":Vector3(.30,.56,-.05),"mag":Vector2(.34,.62),"origin":"butt"},
	"RocketLauncher":{"length":1.05,"muzzle":.60,"right":Vector3(.36,.20,.06),"left":Vector3(.62,.30,-.08),"mag":Vector2(-1.,-1.),"origin":"butt"},
	"GrenadeLauncher":{"length":.74,"muzzle":.72,"right":Vector3(.80,.45,.06),"left":Vector3(.28,.30,-.05),"mag":Vector2(-1.,-1.),"origin":"butt"},
	"Knife_1":{"length":.30,"muzzle":.5,"right":Vector3(.85,.5,0),"left":Vector3(.85,.5,0),"mag":Vector2(-1.,-1.),"origin":"grip","vertical":true},
	"Shovel":{"length":.72,"muzzle":.5,"right":Vector3(.80,.5,0),"left":Vector3(.45,.5,0),"mag":Vector2(-1.,-1.),"origin":"grip","vertical":true},
	"Grenade":{"length":.11,"muzzle":.5,"right":Vector3(.5,.5,0),"left":Vector3(.5,.5,0),"mag":Vector2(-1.,-1.),"origin":"center","vertical":true},
	"FireGrenade":{"length":.14,"muzzle":.5,"right":Vector3(.5,.5,0),"left":Vector3(.5,.5,0),"mag":Vector2(-1.,-1.),"origin":"center","vertical":true}}
func _initialize():call_deferred("run")
# Connected piece id of every triangle (in by_material / names order), by
# welding vertices within half a millimetre (union-find).
static func piece_ids(by_material:Dictionary,names:Array,turn:Basis) -> PackedInt32Array:
	var ids={};var parent=PackedInt32Array()
	var tri_vertex=PackedInt32Array()
	for name in names:
		var verts:PackedVector3Array=by_material[name].v
		for i in range(verts.size()):
			var key=str((turn*verts[i]).snapped(Vector3.ONE*.0005))
			if not ids.has(key):ids[key]=parent.size();parent.append(parent.size())
			tri_vertex.append(ids[key])
	var find=func(i:int) -> int:
		while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
		return i
	for t in range(0,tri_vertex.size(),3):
		for k in range(1,3):
			var a=find.call(tri_vertex[t]);var b=find.call(tri_vertex[t+k])
			if a!=b:parent[a]=b
	var out=PackedInt32Array()
	for t in range(0,tri_vertex.size(),3):out.append(find.call(tri_vertex[t]))
	return out
# Bounds (turned source space) of every piece.
static func piece_bounds(by_material:Dictionary,names:Array,turn:Basis,piece_of:PackedInt32Array) -> Dictionary:
	var out={};var tri=0
	for name in names:
		var verts:PackedVector3Array=by_material[name].v
		for t in range(0,verts.size(),3):
			var id=piece_of[tri];tri+=1
			for k in range(3):
				var p:Vector3=turn*verts[t+k]
				if not out.has(id):out[id]=AABB(p,Vector3.ZERO)
				else:out[id]=out[id].expand(p)
	return out
# A box (half extents, in the given frame) as its own surface, both windings
# so it reads solid from any side.
static func add_box(mesh:ArrayMesh,frame:Transform3D,half:Vector3,mat:Material):
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces=[[Vector3(1,0,0),Vector3(0,1,0),Vector3(0,0,1)],[Vector3(-1,0,0),Vector3(0,0,1),Vector3(0,1,0)],[Vector3(0,1,0),Vector3(0,0,1),Vector3(1,0,0)],[Vector3(0,-1,0),Vector3(1,0,0),Vector3(0,0,1)],[Vector3(0,0,1),Vector3(1,0,0),Vector3(0,1,0)],[Vector3(0,0,-1),Vector3(0,1,0),Vector3(1,0,0)]]
	for f in faces:
		var n:Vector3=f[0];var a:Vector3=f[1];var b:Vector3=f[2]
		var c:Vector3=n*half.abs().dot(n.abs())
		var ea:Vector3=a*half.abs().dot(a.abs());var eb:Vector3=b*half.abs().dot(b.abs())
		var corners=[c-ea-eb,c+ea-eb,c+ea+eb,c-ea+eb]
		var wn:Vector3=(frame.basis*n).normalized()
		for order in [[0,1,2],[0,2,3]]:
			for winding in [true,false]:
				var seq=order if winding else [order[0],order[2],order[1]]
				for i in seq:st.set_normal(wn if winding else -wn);st.add_vertex(frame*corners[i])
	st.set_material(mat);st.commit(mesh)
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
	# Magazine split (1.4.4): whole connected pieces of the model (welded by
	# position) whose centre lies in the magazine u-range and below the
	# receiver, plus the small pieces sitting inside that group's bounds
	# (floor plates). A triangle-by-triangle cut left slivers of the magazine
	# on the body and took part of the receiver with the magazine.
	var mag_range:Vector2=spec.mag
	var piece_of=piece_ids(by_material,names,turn)
	var mag_pieces={};var housing={}
	if mag_range.x>=0.:
		var bounds=piece_bounds(by_material,names,turn,piece_of)
		var union=AABB()
		for id in bounds:
			var b:AABB=bounds[id];var c=b.get_center()
			var u=inverse_lerp(lo.z,hi.z,c.z);var v=inverse_lerp(lo.y,hi.y,c.y);var v_top=inverse_lerp(lo.y,hi.y,b.end.y)
			var low_only=str(spec.origin)=="grip" # pistols: only the floor plate shows below the grip
			if u>=mag_range.x and u<=mag_range.y and v<.45 and v_top<(.12 if low_only else .72):
				mag_pieces[id]=true;union=b if union.size==Vector3.ZERO else union.merge(b)
		if union.size!=Vector3.ZERO:
			var grown=union.grow(.012)
			for id in bounds:
				if mag_pieces.has(id):continue
				var b:AABB=bounds[id];var c=b.get_center()
				# Floor plates inside the group go with the magazine. The magazine
				# housing (the receiver's lower block the magazine goes into: over
				# the same u-span, about as wide, ending below the receiver top)
				# stays on the body but is painted in the receiver's main colour,
				# so it never reads as a piece of magazine left behind.
				if grown.encloses(b) and b.size.y<union.size.y*.5:mag_pieces[id]=true
				elif not (str(spec.origin)=="grip") and c.z>=union.position.z-.02 and c.z<=union.end.z+.02 and inverse_lerp(lo.y,hi.y,b.position.y)<.5 and inverse_lerp(lo.y,hi.y,b.end.y)<.76 and b.size.x<=union.size.x*1.5 and b.size.z<=union.size.z*1.3:housing[id]=true
	var root_node=Node3D.new();root_node.name=base
	var body=MeshInstance3D.new();body.name="Body";root_node.add_child(body);body.owner=root_node
	var mag_mesh=MeshInstance3D.new();mag_mesh.name="Magazine";root_node.add_child(mag_mesh);mag_mesh.owner=root_node
	var body_mesh=ArrayMesh.new();var mag_array=ArrayMesh.new()
	var mag_lo=Vector3.INF;var mag_hi=-Vector3.INF # baked metres
	var top_lo=Vector3.INF;var top_hi=-Vector3.INF # the magazine's top cross-section
	var tri_index=0
	var st_housing=SurfaceTool.new();st_housing.begin(Mesh.PRIMITIVE_TRIANGLES);var any_housing=false
	for name in names:
		var st_body=SurfaceTool.new();st_body.begin(Mesh.PRIMITIVE_TRIANGLES)
		var st_mag=SurfaceTool.new();st_mag.begin(Mesh.PRIMITIVE_TRIANGLES)
		var any_body=false;var any_mag=false
		var verts:PackedVector3Array=by_material[name].v;var norms:PackedVector3Array=by_material[name].n
		for t in range(0,verts.size(),3):
			var in_mag=mag_pieces.has(piece_of[tri_index]);var in_housing=housing.has(piece_of[tri_index]);tri_index+=1
			var st=st_mag if in_mag else st_housing if in_housing else st_body
			if in_mag:any_mag=true
			elif in_housing:any_housing=true
			else:any_body=true
			# Godot's glTF importer already converted the winding.
			for k in [0,1,2]:
				var p:Vector3=place.call(verts[t+k])
				st.set_normal((turn*norms[t+k]).normalized());st.add_vertex(p)
				if in_mag:mag_lo=mag_lo.min(p);mag_hi=mag_hi.max(p)
		var mat=StandardMaterial3D.new();mat.resource_name=name;mat.albedo_color=by_material[name].color
		if any_body:st_body.set_material(mat);st_body.commit(body_mesh)
		if any_mag:st_mag.set_material(mat);st_mag.commit(mag_array)
	if any_housing:
		var main=StandardMaterial3D.new();main.resource_name="Grey";main.albedo_color=by_material.get("Grey",{"color":Color(.5,.5,.5)}).color
		st_housing.set_material(main);st_housing.commit(body_mesh)
	if mag_array.get_surface_count()>0:
		# The top cross-section (vertices within 8 mm of the top) gets a lid on
		# the magazine and a matching plug in the body's well, so neither shows
		# as a hollow shell when the magazine is out.
		tri_index=0
		for name in names:
			var verts:PackedVector3Array=by_material[name].v
			for t in range(0,verts.size(),3):
				var in_mag=mag_pieces.has(piece_of[tri_index]);tri_index+=1
				if not in_mag:continue
				for k in [0,1,2]:
					var p:Vector3=place.call(verts[t+k])
					if p.y>=mag_hi.y-.008:top_lo=top_lo.min(p);top_hi=top_hi.max(p)
		var dark=StandardMaterial3D.new();dark.resource_name="DarkGrey";dark.albedo_color=by_material.get("DarkGrey",{"color":Color(.2,.2,.22)}).color
		if str(spec.origin)=="grip":
			# Pistols: the model shows only the floor plate; a straight box body
			# rises from it inside the grip (raked like the grip) so a magazine
			# comes out of the grip on reload and the grip stays.
			var plate_c=(mag_lo+mag_hi)*.5;var plate_size=mag_hi-mag_lo
			var half=Vector3(plate_size.x*.34,.03,plate_size.z*.30)
			var tilt=float(spec.get("tilt",.2))
			add_box(mag_array,Transform3D(Basis(Vector3.RIGHT,-tilt),Vector3(plate_c.x,mag_hi.y,plate_c.z))*Transform3D(Basis.IDENTITY,Vector3(0,half.y,0)),half,dark)
		else:
			var c=(top_lo+top_hi)*.5;var half=(top_hi-top_lo)*.5
			half.y=.002;half.x=maxf(half.x,.004);half.z=maxf(half.z,.004)
			add_box(mag_array,Transform3D(Basis.IDENTITY,Vector3(c.x,mag_hi.y-.002,c.z)),half,dark)
			add_box(body_mesh,Transform3D(Basis.IDENTITY,Vector3(c.x,mag_hi.y+.003,c.z)),half*Vector3(1.08,1.,1.08),dark)
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
