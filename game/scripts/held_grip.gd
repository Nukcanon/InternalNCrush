class_name HeldGrip
extends Node3D
# Palm and four separate finger arcs enclose the handle; thumb opposes them.
# Local Y is the handle axis, X points from the object into the wrist.
var wrist=Vector3(.105,0,.012)
func build(role:int,radius:float=.025):
	var skin=HumanModel.SKIN_COLORS[role];var glove=Color("45554e")
	MeshFactory.box(self,Vector3(radius+.027,0,.012),Vector3(.047,.103,.052),skin,Vector3.ZERO,.7)
	MeshFactory.box(self,Vector3(radius+.050,.007,.019),Vector3(.018,.088,.043),glove,Vector3.ZERO,.7)
	for finger in range(4):
		var y=.036-finger*.024
		var r=radius+.010
		var points=[]
		for i in range(9):
			var angle=lerpf(.35,4.8,i/8.)
			points.append(Vector3(cos(angle)*r,y,sin(angle)*r))
		for i in range(points.size()-1):segment(points[i],points[i+1],.011 if finger<3 else .0095,skin)
		for point in points:MeshFactory.sphere(self,point,Vector3.ONE*(.022 if finger<3 else .019),skin)
	# Thumb crosses the near face, stopping outside the handle surface.
	segment(Vector3(radius+.035,.047,.015),Vector3(radius+.009,.051,-.019),.014,skin)
	segment(Vector3(radius+.009,.051,-.019),Vector3(.009,.037,-radius-.012),.013,skin)
	wrist=Vector3(radius+.083,0,.012)
	segment(Vector3(radius+.052,.002,.012),wrist,.033,glove)
	MeshFactory.merge_children(self)
func segment(a:Vector3,b:Vector3,radius:float,color:Color):
	var mesh=MeshFactory.cylinder(self,(a+b)*.5,radius,a.distance_to(b),color,Vector3.ZERO,-1,8)
	mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
