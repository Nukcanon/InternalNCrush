class_name OperatorHair
extends RefCounted
## Skull-fitted shell and tied hair, baked with the character.
static var scalp_triangles={}
static var fitted_points={}
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
	if not web:MeshFactory.instance(parent,st.commit(),Vector3.ZERO,color)
	# Web paints the hairline directly onto the exact head triangles; an extra
	# coarse cap would intersect or hover between differently spaced rings.
	# A tapered ponytail follows the skull; no floating beret or cap.
	var back=point(.25,.2,role,web).z+.009
	var tail=HumanModel.loft(parent,Vector3(0,.015,back),[Vector4(-.18,.012,.017,.036),Vector4(-.12,.025,.028,.035),Vector4(-.04,.036,.034,.023),Vector4(.065,.029,.034,0)],color,8 if web else 16)
	tail.rotation.z=.12 if role==1 else -.10
	MeshFactory.cylinder(parent,Vector3(0,.05,back+.004),.033,.016,Color("676271"),Vector3.ZERO,-1.,8)
static func point(u:float,v:float,role:int,web:bool) -> Vector3:
	var angle=u*TAU;var front=clampf(-sin(angle),0.,1.)
	var fringe=smoothstep(.15,.55,front)
	var hem=lerpf(-.007,.052 if role==1 else .057,fringe)+sin(angle*13.)*.0025*fringe
	if not web:
		var swept=.070-.022*exp(-pow((cos(angle)+(.32 if role==1 else -.25))/.55,2))
		hem=lerpf(-.007,swept,fringe)
	var radius=sqrt(maxf(0.,1.-pow(v,4.)))
	if web:
		# Interpolate the actual lightweight 12-sided head, not an oversized oval.
		var y=lerpf(hem,.190,v);var profile=[Vector3(-.033,.065,.067),Vector3(.055,.081,.083),Vector3(.13,.08,.078),Vector3(.18,.052,.053),Vector3(.190,0,0)]
		var section:Vector3=profile[-1]
		for i in range(profile.size()-1):
			if y<=profile[i+1].x:section=profile[i].lerp(profile[i+1],clampf((y-profile[i].x)/(profile[i+1].x-profile[i].x),0,1));break
		var polygon=cos(PI/12.)/cos(fposmod(angle,TAU/12.)-PI/12.)
		return Vector3(cos(angle)*(section.y*polygon+.002),y,sin(angle)*(section.z*polygon+.002))
	return fit_scalp(Vector3(cos(angle)*.098*radius,lerpf(hem,.163,v),sin(angle)*.116*radius+.009),role)
static func fit_scalp(point:Vector3,role:int) -> Vector3:
	var key=str([role,point])
	if fitted_points.has(key):return fitted_points[key]
	if not scalp_triangles.has(role):
		var data=AuthoredHuman.source(role);var triangles=[]
		for face in data.faces:
			if data.vertices[face[0]][1]<1.52 or data.vertices[face[1]][1]<1.52 or data.vertices[face[2]][1]<1.52:continue
			var vertices=[]
			for index in face:
				var p=data.vertices[index];vertices.append(AuthoredHuman.face_point(role,Vector3(p[0],p[1]-1.6,p[2])))
			triangles.append(vertices)
		scalp_triangles[role]=triangles
	var center=Vector3(0,.04,0);var direction=(point-center).normalized();var best=INF;var fitted=point
	for triangle in scalp_triangles[role]:
		var hit=Geometry3D.segment_intersects_triangle(center,center+direction*.5,triangle[0],triangle[1],triangle[2])
		if hit!=null and center.distance_squared_to(hit)<best:
			best=center.distance_squared_to(hit);fitted=hit+direction*.0025
	fitted_points[key]=fitted;return fitted
