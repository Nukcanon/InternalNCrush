class_name HeldGrip
extends Node3D
# Upright object along Y. Palm is on +X, knuckles point -Z; flexion
# curls toward the object, while the wrist continues behind the palm (+Z).
var wrist=Vector3(.055,-.025,.105)
var finger_paths:Array=[]
func build(role:int,radius:float=.025):
	var skin=HumanModel.SKIN_COLORS[role];var glove=Color("45554e")
	var r=radius+.012
	HumanModel.oval(self,Vector3(radius+.024,-.003,.014),Vector3(.043,.100,.079),skin)
	HumanModel.oval(self,Vector3(radius+.043,.001,.019),Vector3(.013,.080,.062),glove)
	for finger in range(4):
		var y=.035-finger*.024;var length=[.077,.086,.080,.064][finger]
		var start=-.58;var sweep=minf(2.55,length/r)
		var points=[]
		for i in range(9):
			var angle=start-sweep*i/8.
			points.append(Vector3(cos(angle)*r,y,sin(angle)*r))
		finger_paths.append(points)
		# Proximal joint grows out of the palm; the curved phalanges remain outside the payload.
		segment(Vector3(radius+.025,y,-.020),points[0],.010,skin)
		for i in range(8):segment(points[i],points[i+1],.0095 if finger<3 else .008,skin)
	# Opposing thumb folds over the rear of the handle, not through its centre.
	segment(Vector3(radius+.025,.041,.032),Vector3(radius*.65,.058,radius+.013),.013,skin)
	segment(Vector3(radius*.65,.058,radius+.013),Vector3(-.006,.040,radius+.017),.011,skin)
	wrist=Vector3(radius+.022,-.018,.108)
	segment(Vector3(radius+.024,-.012,.044),wrist,.030,glove)
	MeshFactory.merge_children(self)
func segment(a:Vector3,b:Vector3,radius:float,color:Color):
	HumanModel.cord(self,a,b,radius,color)
