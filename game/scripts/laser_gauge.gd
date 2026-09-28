class_name LaserGauge
extends Node3D
var bars:Array=[]
var warning:Label3D
func _ready():
	position=Vector3(.095,.108,-.12);rotation_degrees=Vector3(-35,0,0)
	MeshFactory.box(self,Vector3(0,0,0),Vector3(.09,.095,.012),Color("15252d"))
	for i in range(10):
		var mesh=MeshFactory.box(self,Vector3(0,-.037+i*.008,.008),Vector3(.068,.006,.003),Color("53e57d"))
		mesh.material_override=CombatFX.glow(Color("53e57d"));bars.append(mesh)
	warning=Label3D.new();warning.text="⚠ !";warning.font_size=32;warning.pixel_size=.001;warning.position=Vector3(.035,.065,.015);warning.no_depth_test=false;warning.modulate=Color("ff423a");add_child(warning);warning.hide()
func update_heat(heat:float,locked:bool):
	var color=Color("55df75").lerp(Color("ffe251"),minf(1.,heat*2.)) if heat<.5 else Color("ffe251").lerp(Color("ff3434"),(heat-.5)*2.)
	for i in range(bars.size()):bars[i].material_override.albedo_color=color if i<ceili(heat*10.) else Color("263e3b")
	warning.visible=locked
