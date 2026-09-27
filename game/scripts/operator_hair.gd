class_name OperatorHair
extends RefCounted
## Original fitted cap, painted bangs and tied hair; baked with the character.
static func build(parent:Node3D,role:int,web:bool):
	var color=Color("393a43") if role==1 else Color("453b3e")
	var sides=16 if web else 32
	var rings=5 if web else 9
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
	for row in range(rings):
		for col in range(sides):
			var a=point(float(col)/sides,float(row)/rings,role,web)
			var b=point(float(col+1)/sides,float(row)/rings,role,web)
			var c=point(float(col)/sides,float(row+1)/rings,role,web)
			var d=point(float(col+1)/sides,float(row+1)/rings,role,web)
			for p in [a,b,c,b,d,c]:
				st.set_color(color.lightened(.04*maxf(0.,sin(col*.65))).srgb_to_linear());st.add_vertex(p)
	st.generate_normals();st.index()
	MeshFactory.instance(parent,st.commit(),Vector3.ZERO,color)
	# A tapered ponytail follows the skull; no floating beret or cap.
	var tail=HumanModel.loft(parent,Vector3(0,.015,.122),[Vector4(-.18,.012,.017,.036),Vector4(-.12,.025,.028,.035),Vector4(-.04,.036,.034,.023),Vector4(.065,.029,.034,0)],color,8 if web else 16)
	tail.rotation.z=.12 if role==1 else -.10
	MeshFactory.cylinder(parent,Vector3(0,.05,.126),.033,.016,Color("676271"),Vector3.ZERO,-1.,8)
static func point(u:float,v:float,role:int,web:bool) -> Vector3:
	var angle=u*TAU;var front=clampf(-sin(angle),0.,1.)
	var fringe=smoothstep(.15,.55,front)
	var hem=lerpf(-.007,.052 if role==1 else .057,fringe)+sin(angle*13.)*.0025*fringe
	var radius=sqrt(maxf(0.,1.-pow(v,4.)))
	return Vector3(cos(angle)*(.106 if web else .098)*radius,lerpf(hem,.215 if web else .163,v),sin(angle)*(.120 if web else .116)*radius+.009)
