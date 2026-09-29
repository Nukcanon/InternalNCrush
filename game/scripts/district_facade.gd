class_name DistrictFacade
extends RefCounted
## 1.4 cartoon facades. Every street-facing wall ("front", baked by
## tools/maps/bake_districts.py) is dressed as part of a building in the map's
## own style: storeys of framed windows, doors, awnings, cornices, rooflines and
## themed ornaments (a harbour gets corrugated sheds, the library bookshelves).
## Pure visuals merged into one skin mesh and one detail mesh per 24 m tile; the
## wall collision underneath is untouched. Below 2.3 m nothing projects more
## than 12 cm, so players never appear inside a decoration.
const TILE=24.
const PLAIN=0
const TILES=1
const BRICKS=2
const PLANKS=3
const SHINGLES=4
const PANELS=5
# Style per map index (see Rules.MAPS).
const MAP_STYLE=["harbour","shipyard","steelmill","lab","desert","canal","station","oldtown","garage","hillside",
	"orchard","power","plaza","logistics","testlab","derelict","highrise","market","quarry","fortress",
	"nuclear","aqueduct","library","wreckyard","monastery","furnace","greenhouse","vault","coastal_base","server",
	"mountain_fort","range"]
# Keys: pattern, colors (per house), trim, frame, glass, doors, plinth [h,color],
# win [kind,w,h,sill], spacing, shutters, cornice, top, ground, awnings, house
# (house width along a street; 0 = one per lot), roofline (decorative parapets),
# extras. Indoor styles set "indoor": true (walls run floor to ceiling).
const STYLES={
	"oldtown":{"pattern":PLAIN,"colors":["5f82b9","c9a36d","8a7fc0","5aa08f","c9756a","d9b45a","7fa7c9"],"trim":"dcd6c9","frame":"ece7dc","glass":"4d5f70","doors":["4f5d6b","6b4f3f","3f5f55","7a3f3a"],
		"plinth":[.45,"b9b2a3"],"win":["rect",1.1,1.3,.95],"spacing":3.0,"shutters":["3f6b55","8a4a3a",""],"cornice":true,"top":"cornice","ground":"door",
		"awnings":[["4f8f7a","4f8f7a"],["a0765a","a0765a"],["5a6f9a","5a6f9a"]],"house":6.5,"roofline":true,"extras":["drain","flowers","lantern"]},
	"hillside":{"pattern":PLAIN,"colors":["f1ece0","e8d7b8","cfe0e6","f0d6cf","dfe8cf"],"trim":"b5563e","frame":"5a88b8","glass":"3f5566","doors":["3d6fa8","2f8a8a","b0533c"],
		"plinth":[.6,"9a8f7f"],"win":["grille",.9,1.0,1.0],"spacing":2.8,"shutters":[],"cornice":false,"top":"eave","ground":"door",
		"awnings":[],"house":5.,"roofline":true,"extras":["drain","flowers","pots"]},
	"canal":{"pattern":BRICKS,"colors":["a9553f","6b4a3a","c47d4c","3f5b6b","7d8c5a","b8894f"],"trim":"f2ede2","frame":"f2ede2","glass":"3b4c59","doors":["2f3f36","5a2f2a","26394d"],
		"plinth":[.5,"4a4a48"],"win":["tall",1.0,1.7,.8],"spacing":2.2,"shutters":[],"cornice":false,"top":"steps","ground":"door",
		"awnings":[],"house":4.4,"roofline":false,"extras":["hoist","flowers"]},
	"plaza":{"pattern":PLAIN,"colors":["e3c9a2","dca796","b3c6a6","e6cf94","c6b0cf"],"trim":"fbf6ea","frame":"fbf6ea","glass":"52697a","doors":["6a4a3a","465a6a"],
		"plinth":[.35,"d6cbb5"],"win":["arch",1.1,1.6,.7],"spacing":3.2,"shutters":["6f8a6a","8a6a5a"],"cornice":true,"top":"balustrade","ground":"arcade",
		"awnings":[],"house":7.,"roofline":true,"extras":["balcony","lantern","pilasters"]},
	"market":{"pattern":BRICKS,"colors":["d98c5f","e3c16f","8fb3a0","c96f6f","b7a07a","e6a95a"],"trim":"efe6d2","frame":"efe6d2","glass":"455868","doors":["7a5a3a","4a5a4a"],
		"plinth":[.3,"8f8373"],"win":["rect",1.0,1.1,1.0],"spacing":2.8,"shutters":[],"cornice":true,"top":"parapet","ground":"shop",
		"awnings":[["d24c3f","f4ead7"],["2f7fbf","f4ead7"],["2f9a6a","f4ead7"],["e0a02f","f4ead7"],["7a4fa0","f4ead7"]],"house":5.,"roofline":true,"extras":["signs","lantern","crates"]},
	"station":{"pattern":BRICKS,"colors":["b5523f","a9493a","c0634a"],"trim":"eadfc6","frame":"3f5a4a","glass":"57707f","doors":["3f5a4a"],
		"plinth":[.9,"d9ceb4"],"win":["arch",1.3,1.7,.7],"spacing":3.6,"shutters":[],"cornice":true,"top":"cornice","ground":"door",
		"awnings":[],"house":0.,"roofline":false,"extras":["pilasters","clock","lantern"]},
	"harbour":{"pattern":PANELS,"colors":["4f8fb8","d8705a","e3e5df","f0c24f","5a9a8a"],"trim":"f4f1e8","frame":"f4f1e8","glass":"3e5566","doors":["44525c","a54a3a"],
		"plinth":[.4,"7a8288"],"win":["rect",1.2,.8,2.0],"spacing":4.0,"shutters":[],"cornice":false,"top":"parapet","ground":"roller",
		"awnings":[],"house":0.,"roofline":false,"extras":["ribs","numbers","lifebuoy","drain"]},
	"shipyard":{"pattern":PANELS,"colors":["6f8c9b","d8b44c","3f5f7a","9aa4a8"],"trim":"e9c35a","frame":"e9eef0","glass":"4a6273","doors":["3a4650"],
		"plinth":[.6,"2f3a40"],"win":["band",0.,.9,4.2],"spacing":4.0,"shutters":[],"cornice":false,"top":"rail","ground":"roller",
		"awnings":[],"house":0.,"roofline":false,"extras":["ribs","girders","hazard","numbers"]},
	"logistics":{"pattern":PANELS,"colors":["4c78a8","8b9aa4","3f8f7f","c96a3f"],"trim":"f0c24f","frame":"e8ecef","glass":"42596a","doors":["3a4650"],
		"plinth":[.9,"8a8f93"],"win":["band",0.,.7,4.6],"spacing":4.2,"shutters":[],"cornice":false,"top":"parapet","ground":"dock",
		"awnings":[],"house":0.,"roofline":false,"extras":["ribs","numbers","hazard"]},
	"desert":{"pattern":PLAIN,"colors":["e2b87b","d9a86a","caa27a","e6c796"],"trim":"b88752","frame":"8a6a4a","glass":"3b3f45","doors":["6f7a4a","8a5a3a"],
		"plinth":[.5,"c49a62"],"win":["slit",.5,.9,1.3],"spacing":2.6,"shutters":[],"cornice":false,"top":"round","ground":"door",
		"awnings":[["8a8f5a","8a8f5a"],["b5a06a","b5a06a"]],"house":0.,"roofline":true,"extras":["sandbags","vents","camo"]},
	"orchard":{"pattern":PLANKS,"colors":["b5483a","c98a4a","e8dcc0","8a5a3a"],"trim":"f2ead8","frame":"f2ead8","glass":"3f4b52","doors":["b5483a","6a4a32"],
		"plinth":[.5,"8f8676"],"win":["rect",.9,.9,1.2],"spacing":3.4,"shutters":["f2ead8"],"cornice":false,"top":"eave","ground":"barn",
		"awnings":[],"house":0.,"roofline":false,"extras":["beams","hay","lantern"]},
	"quarry":{"pattern":BRICKS,"colors":["b9a07d","a8916e","c4b08e"],"trim":"6b4f36","frame":"6b4f36","glass":"3b4046","doors":["6b4f36"],
		"plinth":[1.2,"8f8577"],"win":["rect",.9,.9,1.3],"spacing":3.4,"shutters":[],"cornice":false,"top":"eave","ground":"door",
		"awnings":[],"house":0.,"roofline":false,"extras":["beams","shoring","hazard"]},
	"fortress":{"pattern":BRICKS,"colors":["b9ae98","a9a08c","c4b9a2"],"trim":"8f8674","frame":"5a4a3a","glass":"26292c","doors":["6b4a2f"],
		"plinth":[1.0,"958b78"],"win":["slit",.3,1.3,1.6],"spacing":3.0,"shutters":[],"cornice":false,"top":"crenel","ground":"gate",
		"awnings":[],"house":0.,"roofline":false,"extras":["banners","torches","buttress"]},
	"mountain_fort":{"pattern":BRICKS,"colors":["8f8a7c","9c9484","7f7a6e"],"trim":"5f5548","frame":"6b4a2f","glass":"26292c","doors":["6b4a2f"],
		"plinth":[1.4,"6f6a60"],"win":["slit",.35,1.1,1.8],"spacing":3.4,"shutters":[],"cornice":false,"top":"crenel","ground":"gate",
		"awnings":[],"house":0.,"roofline":false,"extras":["beams","banners","ivy","torches"]},
	"monastery":{"pattern":PLAIN,"colors":["f1ece0","ece4d2","f4efe4"],"trim":"b5634a","frame":"6b4a32","glass":"3f5a6a","doors":["6b4a32"],
		"plinth":[.7,"c9bfa9"],"win":["arch",.8,1.4,1.3],"spacing":3.2,"shutters":[],"cornice":true,"top":"tiles","ground":"archdoor",
		"awnings":[],"house":0.,"roofline":false,"extras":["buttress","ivy","bell"]},
	"aqueduct":{"pattern":BRICKS,"colors":["d99a6a","c98a5a","e0aa7a"],"trim":"f0dcc0","frame":"8a5a3a","glass":"3f4f5a","doors":["7a4a32"],
		"plinth":[.6,"b98060"],"win":["arch",1.0,1.4,1.1],"spacing":3.4,"shutters":["5f7a5a"],"cornice":true,"top":"tiles","ground":"blindarch",
		"awnings":[],"house":0.,"roofline":false,"extras":["ivy","pots"]},
	"nuclear":{"pattern":PANELS,"colors":["e8eceb","d6dedf","c9d4d6"],"trim":"f0c23f","frame":"7f8a90","glass":"4a6a7a","doors":["5a6a72"],
		"plinth":[.6,"9aa4a8"],"win":["band",0.,.6,2.2],"spacing":4.0,"shutters":[],"cornice":false,"top":"rail","ground":"airlock",
		"awnings":[],"house":0.,"roofline":false,"extras":["stripe","vents","trefoil","pipes"]},
	"wreckyard":{"pattern":PANELS,"colors":["8a6a52","6f7a7a","7a5a4a","5f6a66"],"trim":"b0652f","frame":"4a4f52","glass":"2a3036","doors":["4a4f52"],
		"plinth":[.5,"4f4a44"],"win":["broken",1.1,1.0,1.4],"spacing":3.4,"shutters":[],"cornice":false,"top":"jagged","ground":"roller",
		"awnings":[],"house":0.,"roofline":false,"extras":["rust","ribs","pipes"]},
	"furnace":{"pattern":BRICKS,"colors":["5a3f36","6b4a3f","4f3a33"],"trim":"2f2a28","frame":"2f2a28","glass":"f0a040","doors":["2f2a28"],
		"plinth":[.8,"3a3330"],"win":["glow",1.0,1.0,2.0],"spacing":3.6,"shutters":[],"cornice":false,"top":"rail","ground":"roller",
		"awnings":[],"house":0.,"roofline":false,"extras":["pipes","girders","hazard","vents"]},
	"greenhouse":{"pattern":TILES,"colors":["f4f6f2"],"trim":"f4f6f2","frame":"f4f6f2","glass":"9fd6cf","doors":["4f7a5a"],
		"plinth":[.7,"b9a88f"],"win":["grid",0.,0.,.7],"spacing":1.4,"shutters":[],"cornice":false,"top":"rail","ground":"glass",
		"awnings":[],"house":0.,"roofline":false,"extras":["planters","vines"]},
	"coastal_base":{"pattern":PANELS,"colors":["8f9a8a","a3a89a","7f8a7c"],"trim":"d8d2c0","frame":"4f5a52","glass":"2f3a40","doors":["4f5a52"],
		"plinth":[.8,"6f766c"],"win":["slit",1.4,.35,1.6],"spacing":3.6,"shutters":[],"cornice":false,"top":"parapet","ground":"bunker",
		"awnings":[],"house":0.,"roofline":false,"extras":["stripe","sandbags","antenna","numbers"]},
	"range":{"pattern":PLANKS,"colors":["d9b98a","c9a878","e0c79a"],"trim":"e05a3a","frame":"6b5a44","glass":"2f3438","doors":["6b5a44"],
		"plinth":[.3,"a08a68"],"win":["open",1.4,1.1,1.0],"spacing":3.8,"shutters":[],"cornice":false,"top":"rail","ground":"door",
		"awnings":[],"house":0.,"roofline":false,"extras":["targets","numbers","hazard"]},
	# Interiors: walls run to the ceiling.
	"steelmill":{"indoor":true,"pattern":BRICKS,"colors":["7a4a3a","6b4034"],"trim":"e0b03a","frame":"3a3f44","glass":"9fb8c4","doors":["3a4046"],
		"plinth":[1.1,"4a4c4f"],"win":["band",0.,1.2,4.6],"spacing":4.,"top":"none","ground":"roller","extras":["girders","pipes","hazard"]},
	"lab":{"indoor":true,"pattern":TILES,"colors":["eef3f4","e4eef0"],"trim":"3fb8c0","frame":"b8c4c8","glass":"a8d8e0","doors":["8fa0a8"],
		"plinth":[1.3,"d4e4e8"],"win":["rect",1.8,1.2,1.0],"spacing":4.,"top":"none","ground":"airlock","extras":["stripe","cabinets","vents"]},
	"garage":{"indoor":true,"pattern":BRICKS,"colors":["cfd6dc","c4ccd2"],"trim":"2f5f8f","frame":"3a4a5a","glass":"a8c4d8","doors":["e0a02f"],
		"plinth":[1.3,"3f6fa0"],"win":["rect",1.6,1.0,2.2],"spacing":4.,"top":"none","ground":"roller","extras":["toolboards","lockers","tyres","oil"]},
	"power":{"indoor":true,"pattern":PANELS,"colors":["8fa89a","86a092"],"trim":"e0c040","frame":"3a4a44","glass":"a0c0c8","doors":["3a4a44"],
		"plinth":[.6,"4f5f58"],"win":["none",0.,0.,0.],"spacing":4.,"top":"none","ground":"door","extras":["pipes","bigpipes","gauges","cabinets","warning"]},
	"testlab":{"indoor":true,"pattern":TILES,"colors":["f2f2ea","e8ecdf"],"trim":"e07a2f","frame":"8a9488","glass":"b0d8c8","doors":["e07a2f"],
		"plinth":[1.2,"c8d4bc"],"win":["rect",2.2,1.1,1.0],"spacing":4.2,"top":"none","ground":"airlock","extras":["stripe","cabinets","vents","biohazard"]},
	"derelict":{"indoor":true,"pattern":BRICKS,"colors":["8a5a44","7a5040","6f6a60"],"trim":"5a524a","frame":"3a3632","glass":"6a8a8a","doors":["4a4640"],
		"plinth":[.8,"4f4a44"],"win":["broken",1.6,1.6,3.6],"spacing":3.8,"top":"none","ground":"roller","extras":["rust","pipes","graffiti"]},
	"highrise":{"indoor":true,"pattern":PANELS,"colors":["d8d4cc","cfd6da"],"trim":"6a7a86","frame":"3f4a52","glass":"8fb8d8","doors":["5a4a3a"],
		"plinth":[1.0,"8a6f55"],"win":["tall",2.2,2.8,.9],"spacing":3.4,"top":"none","ground":"door","extras":["wainscot","plants","artwork"]},
	"library":{"indoor":true,"pattern":PLANKS,"colors":["e7d3af","dcc39a"],"trim":"6b4630","frame":"6b4630","glass":"a8c0c8","doors":["6b4630"],
		"plinth":[.3,"6b4630"],"win":["arch",1.1,1.5,3.3],"spacing":3.6,"top":"none","ground":"archdoor","extras":["books","pilasters","lamps"]},
	"vault":{"indoor":true,"pattern":PANELS,"colors":["8a949c","7f8990"],"trim":"d8a93a","frame":"4a5258","glass":"3a4248","doors":["b8a060"],
		"plinth":[1.0,"5a6268"],"win":["none",0.,0.,0.],"spacing":4.,"top":"none","ground":"vault","extras":["rivets","stripe","deposit","vaultdoor"]},
	"server":{"indoor":true,"pattern":TILES,"colors":["d6dde2","c8d2d8"],"trim":"2fb8e0","frame":"4a5560","glass":"a0c8e0","doors":["4a5560"],
		"plinth":[.2,"5a6670"],"win":["none",0.,0.,0.],"spacing":4.,"top":"none","ground":"airlock","extras":["racks","cable_tray","stripe"]}}
# Ground (outdoor) / floor + ceiling (indoor): [color, pattern].
const GROUNDS={"oldtown":["d6c8a8",TILES],"hillside":["c8bca2",TILES],"canal":["b9bdb8",TILES],"plaza":["e0d2b8",TILES],"market":["c9b89a",BRICKS],
	"station":["cfc6b4",TILES],"harbour":["9aa0a2",PANELS],"shipyard":["8f9496",PANELS],"logistics":["a0a4a6",PANELS],"desert":["d9bf8a",PLAIN],
	"orchard":["b8a57e",PLAIN],"quarry":["c4b08e",PLAIN],"fortress":["b0a894",BRICKS],"mountain_fort":["a39c8c",BRICKS],"monastery":["d8cfbd",TILES],
	"aqueduct":["d4b894",BRICKS],"nuclear":["b8bfc2",PANELS],"wreckyard":["8a8076",PANELS],"furnace":["6f6660",PANELS],"greenhouse":["a9b98a",TILES],
	"coastal_base":["9aa08f",PANELS],"range":["c2ab84",PLAIN],
	"steelmill":["6f6a64",PANELS],"lab":["dfe6e8",TILES],"garage":["8a8f93",TILES],"power":["7f8a84",PANELS],"testlab":["d4dcc8",TILES],
	"derelict":["7a7068",TILES],"highrise":["8a6f55",PLANKS],"library":["8a5a3a",PLANKS],"vault":["6a7278",PANELS],"server":["b8c0c6",TILES]}
const CEILINGS={"steelmill":["4a4c4f",PANELS],"lab":["eef2f3",TILES],"garage":["6a6e72",PANELS],"power":["5f6a64",PANELS],"testlab":["e8ecd8",TILES],
	"derelict":["5a524a",PLANKS],"highrise":["ecebe6",TILES],"library":["c9a878",PLANKS],"vault":["5a6268",PANELS],"server":["d6dde2",TILES]}
static var skin_materials={}
static var storey_height=3.1 # current map storey (windows fit inside one storey)
static func style_for(index:int) -> Dictionary:return STYLES[MAP_STYLE[clampi(index,0,MAP_STYLE.size()-1)]]
static func style_name(index:int) -> String:return MAP_STYLE[clampi(index,0,MAP_STYLE.size()-1)]
static func skin_material(index:int) -> ShaderMaterial:
	if skin_materials.has(index):return skin_materials[index]
	var mat:ShaderMaterial=WorldSurface.material("wall",index).duplicate()
	mat.set_shader_parameter("vertex_paint",true);mat.set_shader_parameter("pattern",int(style_for(index).pattern))
	mat.set_shader_parameter("tile_meters",1.3 if int(style_for(index).pattern)==BRICKS else 2.4);mat.set_shader_parameter("line_strength",.12)
	skin_materials[index]=mat;return mat

## Geometry kit: vertex-colour quads/boxes in a front's local frame
## (x along the wall, y world height, z out toward the street).
class Kit:
	var skin:SurfaceTool
	var detail:SurfaceTool
	var xf:=Transform3D()
	var tris=0
	func _init():
		skin=SurfaceTool.new();skin.begin(Mesh.PRIMITIVE_TRIANGLES)
		detail=SurfaceTool.new();detail.begin(Mesh.PRIMITIVE_TRIANGLES)
	# bl, br, tr, tl as seen from the front.
	func quad4(st:SurfaceTool,bl:Vector3,br:Vector3,tr:Vector3,tl:Vector3,col:Color):
		var n=(xf.basis*(br-bl).cross(tl-bl)).normalized()
		if n==Vector3.ZERO:n=xf.basis*(tr-bl).cross(tl-br).normalized()
		for p in [bl,tl,br,br,tl,tr]:st.set_color(col);st.set_normal(n);st.add_vertex(xf*p)
		tris+=2
	func quad(p:Vector3,ex:Vector3,ey:Vector3,col:Color,st:SurfaceTool=null):
		quad4(st if st else detail,p,p+ex,p+ex+ey,p+ey,col)
	# Axis-aligned box (local frame); the back face is omitted (it sits on the wall).
	func box(c:Vector3,s:Vector3,col:Color,back:=false,bottom:=true):
		var h=s*.5
		quad(c+Vector3(-h.x,-h.y,h.z),Vector3(s.x,0,0),Vector3(0,s.y,0),col)
		quad(c+Vector3(-h.x,h.y,h.z),Vector3(s.x,0,0),Vector3(0,0,-s.z),col.lightened(.06))
		if bottom:quad(c+Vector3(-h.x,-h.y,-h.z),Vector3(s.x,0,0),Vector3(0,0,s.z),col.darkened(.12))
		quad(c+Vector3(-h.x,-h.y,-h.z),Vector3(0,0,s.z),Vector3(0,s.y,0),col.darkened(.06))
		quad(c+Vector3(h.x,-h.y,h.z),Vector3(0,0,-s.z),Vector3(0,s.y,0),col.darkened(.06))
		if back:quad(c+Vector3(h.x,-h.y,-h.z),Vector3(-s.x,0,0),Vector3(0,s.y,0),col.darkened(.1))
	# Wall-hugging box: from the wall plane (z=0) out to depth.
	func slab(x0:float,x1:float,y0:float,y1:float,depth:float,col:Color,z0:=0.):
		box(Vector3((x0+x1)*.5,(y0+y1)*.5,z0+depth*.5),Vector3(x1-x0,y1-y0,depth),col)
	# Flat disc (n-gon) facing the street.
	func disc(c:Vector3,r:float,col:Color,sides:=8):
		for i in range(sides):
			var a=TAU*i/sides;var b=TAU*(i+1)/sides
			var p=c+Vector3(cos(a)*r,sin(a)*r,0);var q=c+Vector3(cos(b)*r,sin(b)*r,0)
			var n=xf.basis.z.normalized()
			for v in [c,q,p]:detail.set_color(col);detail.set_normal(n);detail.add_vertex(xf*v)
			tris+=1
	# Half disc (arch head) above y, radius r.
	func arch(cx:float,y:float,z:float,r:float,col:Color,sides:=6):
		for i in range(sides):
			var a=PI*i/sides;var b=PI*(i+1)/sides
			var c=Vector3(cx,y,z);var p=c+Vector3(cos(a)*r,sin(a)*r,0);var q=c+Vector3(cos(b)*r,sin(b)*r,0)
			var n=xf.basis.z.normalized()
			for v in [c,q,p]:detail.set_color(col);detail.set_normal(n);detail.add_vertex(xf*v)
			tris+=1
	# Upright n-sided prism standing on base (barrels, posts, drums).
	func prism(base:Vector3,r:float,h:float,col:Color,sides:=8,cap:=true):
		for i in range(sides):
			var a=TAU*i/sides;var b=TAU*(i+1)/sides
			var p=base+Vector3(cos(a)*r,0,sin(a)*r);var q=base+Vector3(cos(b)*r,0,sin(b)*r)
			quad4(detail,q,p,p+Vector3.UP*h,q+Vector3.UP*h,col.darkened(.04*(i%2)))
			if cap:
				var n=xf.basis.y.normalized();var c=base+Vector3.UP*h
				for v in [c,p+Vector3.UP*h,q+Vector3.UP*h]:detail.set_color(col.lightened(.06));detail.set_normal(n);detail.add_vertex(xf*v)
				tris+=1
	# Arch ring (frame) of thickness t.
	func arch_ring(cx:float,y:float,z:float,r:float,t:float,col:Color,sides:=6):
		for i in range(sides):
			var a=PI*i/sides;var b=PI*(i+1)/sides
			var c=Vector3(cx,y,z)
			var p0=c+Vector3(cos(a)*r,sin(a)*r,0);var p1=c+Vector3(cos(b)*r,sin(b)*r,0)
			var q0=c+Vector3(cos(a)*(r+t),sin(a)*(r+t),0);var q1=c+Vector3(cos(b)*(r+t),sin(b)*(r+t),0)
			quad4(detail,p0,q0,q1,p1,col)

## Builds every front of the map. Returns wall light fixtures.
static func build(a:Node,plan:Dictionary) -> Array:
	var index:int=a.map_index
	var style=style_for(index)
	var kits={}
	var fixtures=[]
	var storey=float(plan.get("storey",3.1))
	storey_height=storey
	var lite=RenderStyle.web()
	for f in plan.get("fronts",[]):
		var u=Vector3(f[0],0,f[1]);var v=Vector3(f[2],0,f[3])
		var mid=(u+v)*.5
		var key=Vector2i(floori(mid.x/TILE),floori(mid.z/TILE))
		if not kits.has(key):kits[key]=Kit.new()
		var kit:Kit=kits[key]
		var d=(v-u);var length=d.length()
		if length<.8:continue
		d/=length
		var n=Vector3(-d.z,0,d.x)
		kit.xf=Transform3D(Basis(d,Vector3.UP,n),u)
		var piece={"length":length,"y0":float(f[4]),"y1":float(f[5]),"from":float(f[6]),"top":float(f[7]),"lot":int(f[8]),"flags":int(f[9]),"storey":storey,"lite":lite,"index":index}
		front(kit,style,piece,fixtures)
	for key in kits:
		var kit:Kit=kits[key]
		for pair in [[kit.skin,skin_material(index),"FacadeSkin"],[kit.detail,WorldSurface.material("detail",index,true),"FacadeDetail"]]:
			var st:SurfaceTool=pair[0]
			var mesh=st.commit()
			if mesh.get_surface_count()==0:continue
			var node=MeshInstance3D.new();node.name=pair[2];node.mesh=mesh;node.material_override=pair[1]
			# Skins (building colours) are always drawn; ornaments fade out far away.
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if pair[2]=="FacadeDetail":node.visibility_range_end=90.;node.visibility_range_end_margin=8.
			a.architecture.add_child(node)
	a.set_meta("facade_style",style_name(index));a.set_meta("facade_tiles",kits.size())
	return fixtures

static func pick(list:Array,hs:int):
	return list[absi(hs)%list.size()] if not list.is_empty() else null
static func hashi(a:int,b:int) -> int:return absi((a*73856093)^(b*19349663))%100003

## One wall piece: split into houses, then storeys and bays.
static func front(kit:Kit,style:Dictionary,p:Dictionary,fixtures:Array):
	var length:float=p.length
	var house_width=float(style.get("house",0.))
	var count=1 if house_width<=0. or p.flags&3!=0 else maxi(1,roundi(length/house_width))
	var width=length/count
	for h in range(count):
		var x0=h*width;var x1=x0+width
		var hs=hashi(p.lot,h+roundi(p.from))
		var y0=lerpf(p.y0,p.y1,x0/length);var y1=lerpf(p.y0,p.y1,x1/length)
		house(kit,style,p,x0,x1,y0,y1,hs,fixtures)

static func house(kit:Kit,style:Dictionary,p:Dictionary,x0:float,x1:float,y0:float,y1:float,hs:int,fixtures:Array):
	var indoor=bool(style.get("indoor",false))
	var room=p.flags&1!=0 # inside a covered room (ceiling at one storey)
	var over=p.flags&2!=0 # upper wall above a covered room's opening
	var near_deck=p.flags&4!=0
	var storey:float=p.storey
	var base=p.from
	var top:float=p.top
	var wall=Color(pick(style.colors,hs))
	if room:wall=Color(pick(style.colors,hs)).lightened(.25)
	var trim=Color(style.trim);var frame=Color(style.frame);var glass=Color(style.glass)
	var level=maxf(y0,y1)
	var slope=absf(y1-y0)
	var w=x1-x0
	# Skin: the building's own colour over the wall (pattern from the style).
	kit.quad4(kit.skin,Vector3(x0,y0+base,.03),Vector3(x1,y1+base,.03),Vector3(x1,y1+top,.03),Vector3(x0,y0+top,.03),wall)
	# Decorative roofline: parapets of varying height give a lively skyline.
	var crown=top
	if style.get("roofline",false) and not room and not indoor:
		var extra=[0.,.5,1.1,1.7][hs%4]
		if extra>0.:
			crown=top+extra
			kit.slab(x0,x1,minf(y0,y1)+top-.02,minf(y0,y1)+crown,.3,wall,-.27)
	# Plinth.
	if base<=0. and not style.plinth.is_empty():
		sloped_band(kit,x0,x1,y0,y1,0.,float(style.plinth[0]),.012,Color(style.plinth[1]))
	if room:
		# Interior of a covered room: wainscot and a picture rail.
		sloped_band(kit,x0,x1,y0,y1,0.,1.0,.03,wall.darkened(.18))
		sloped_band(kit,x0,x1,y0,y1,1.0,1.08,.05,trim)
		if w>2.6 and hs%3==0:shelf(kit,(x0+x1)*.5,level,Color(style.frame),hs)
		return
	var floors=maxi(1,floori((top-base)/storey+.01))
	if indoor:floors=1
	var spacing=float(style.spacing)
	var bays=maxi(1,floori(w/spacing))
	if w<1.6:bays=0
	# Storeys.
	for s in range(floors):
		var bottom=base+s*storey
		if indoor:bottom=0.
		var ground=bottom<=.01
		if ground and not over:
			ground_floor(kit,style,p,x0,x1,y0,y1,bays,hs,fixtures)
		elif not indoor:
			for b in range(bays):
				var cx=x0+w*(b+.5)/bays
				window(kit,style,cx,level+bottom,hs+b*7,near_deck)
			if style.extras.has("balcony") and not near_deck and s==1 and hs%2==0 and w>3.:
				balcony(kit,(x0+x1)*.5,level+bottom,minf(w-.6,3.2),trim)
			if style.extras.has("banners") and s>=1 and hs%3==0:
				banner(kit,(x0+x1)*.5,level+bottom+storey-.3,hs)
		if style.get("cornice",false) and s>0 and not indoor:
			sloped_band(kit,x0,x1,y0,y1,bottom,bottom+.14,.1,trim)
	if indoor:
		interior(kit,style,p,x0,x1,y0,y1,level,top,hs,fixtures)
	# Top edge.
	roof_edge(kit,style,x0,x1,minf(y0,y1)+crown,trim,wall,hs)
	extras(kit,style,p,x0,x1,y0,y1,level,crown,hs,fixtures)

static func sloped_band(kit:Kit,x0:float,x1:float,y0:float,y1:float,lo:float,hi:float,depth:float,col:Color):
	var z=.03+depth
	kit.quad4(kit.detail,Vector3(x0,y0+lo,z),Vector3(x1,y1+lo,z),Vector3(x1,y1+hi,z),Vector3(x0,y0+hi,z),col)
	kit.quad4(kit.detail,Vector3(x0,y0+hi,z),Vector3(x1,y1+hi,z),Vector3(x1,y1+hi,.03),Vector3(x0,y0+hi,.03),col.lightened(.06))
	kit.quad4(kit.detail,Vector3(x0,y0+lo,.03),Vector3(x1,y1+lo,.03),Vector3(x1,y1+lo,z),Vector3(x0,y0+lo,z),col.darkened(.12))

## Windows by kind. y = storey floor level; sill height from the style.
static func window(kit:Kit,style:Dictionary,cx:float,y:float,hs:int,near_deck:bool):
	var kind=str(style.win[0]);var ww=float(style.win[1]);var wh=float(style.win[2]);var sill=float(style.win[3])
	var frame=Color(style.frame);var glass=Color(style.glass);var trim=Color(style.trim)
	# A window (with its arch head) always fits inside one storey.
	if not bool(style.get("indoor",false)):
		var room=storey_height-sill-.3-(ww*.5 if kind=="arch" else 0.)
		if wh>room:
			sill=maxf(.5,storey_height-.3-(ww*.5 if kind=="arch" else 0.)-wh)
			wh=minf(wh,storey_height-sill-.3-(ww*.5 if kind=="arch" else 0.))
	var yb=y+sill
	match kind:
		"none":return
		"band":
			return # bands are drawn per house in extras (continuous strip)
		"grid":
			return
		"slit":
			kit.slab(cx-ww*.5-.08,cx+ww*.5+.08,yb-.08,yb+wh+.08,.05,frame.lightened(.15))
			kit.quad(Vector3(cx-ww*.5,yb,.09),Vector3(ww,0,0),Vector3(0,wh,0),glass)
			return
		"open":
			# Training-range window: an opening with a plywood frame.
			kit.slab(cx-ww*.5-.12,cx+ww*.5+.12,yb-.12,yb,.1,frame)
			kit.quad(Vector3(cx-ww*.5,yb,.05),Vector3(ww,0,0),Vector3(0,wh,0),glass)
			for side in [-1,1]:kit.slab(cx+side*(ww*.5+.06)-.06,cx+side*(ww*.5+.06)+.06,yb,yb+wh,.08,frame)
			kit.slab(cx-ww*.5-.12,cx+ww*.5+.12,yb+wh,yb+wh+.1,.08,frame)
			return
	# Framed window (rect/tall/grille/broken/glow/arch).
	var f=.09
	kit.slab(cx-ww*.5-f,cx+ww*.5+f,yb-f,yb+wh+f,.05,frame)
	var pane=glass
	if kind=="glow":pane=Color("ffb347")
	kit.quad(Vector3(cx-ww*.5,yb,.085),Vector3(ww,0,0),Vector3(0,wh,0),pane)
	if kind=="broken":
		kit.quad(Vector3(cx-ww*.1,yb+wh*.35,.087),Vector3(ww*.55,0,0),Vector3(0,wh*.45,0),Color("15181b"))
	if kind=="arch":
		kit.arch(cx,yb+wh,.085,ww*.5,pane)
		kit.arch_ring(cx,yb+wh,.09,ww*.5,.1,frame)
	# Mullions.
	kit.slab(cx-.03,cx+.03,yb,yb+wh,.1,frame)
	if kind in ["rect","tall","broken"]:kit.slab(cx-ww*.5,cx+ww*.5,yb+wh*.55-.03,yb+wh*.55+.03,.1,frame)
	if kind=="grille":
		for i in [-1,1]:kit.slab(cx+i*ww*.25-.02,cx+i*ww*.25+.02,yb,yb+wh,.11,Color("3a3a3a"))
	# Sill.
	kit.slab(cx-ww*.5-.16,cx+ww*.5+.16,yb-f-.07,yb-f,.12,trim)
	# Shutters.
	var shutters:Array=style.get("shutters",[])
	if not shutters.is_empty():
		var sc=pick(shutters,hs/3)
		if sc!=null and sc!="":
			for side in [-1,1]:
				var sx=cx+side*(ww*.5+f+ww*.25)
				kit.slab(sx-ww*.25,sx+ww*.25,yb-.02,yb+wh+.02,.04,Color(sc))
				for k in range(3):kit.slab(sx-ww*.22,sx+ww*.22,yb+wh*(k+.5)/3.-.02,yb+wh*(k+.5)/3.+.02,.06,Color(sc).darkened(.2))
	# Flower box under some upper windows.
	if style.extras.has("flowers") and hs%3==0 and not near_deck:
		kit.slab(cx-ww*.5,cx+ww*.5,yb-f-.3,yb-f-.07,.22,Color("8a5a3a"))
		for k in range(4):
			var fx=cx-ww*.4+k*ww*.8/3.
			kit.box(Vector3(fx,yb-f,.14),Vector3(.18,.16,.16),Color(["d9577a","f0c24f","e07a5f","8fbf5a"][(hs+k)%4]))

static func door(kit:Kit,style:Dictionary,cx:float,y:float,dw:float,dh:float,hs:int,kind:="door"):
	var frame=Color(style.trim);var col=Color(pick(style.doors,hs))
	match kind:
		"roller":
			kit.slab(cx-dw*.5-.18,cx+dw*.5+.18,y,y+dh+.22,.05,Color(style.frame).darkened(.2))
			kit.slab(cx-dw*.5,cx+dw*.5,y,y+dh,.07,col.lightened(.1))
			for k in range(int(dh/.25)):kit.slab(cx-dw*.5,cx+dw*.5,y+k*.25+.1,y+k*.25+.13,.09,col.darkened(.12))
			kit.slab(cx-dw*.5-.1,cx+dw*.5+.1,y+dh,y+dh+.3,.12,col.darkened(.2))
			return
		"barn":
			kit.slab(cx-dw*.5-.12,cx+dw*.5+.12,y,y+dh+.12,.05,frame)
			kit.slab(cx-dw*.5,cx+dw*.5,y,y+dh,.07,col)
			for side in [-1,1]:
				var mx=cx+side*dw*.25
				kit.slab(mx-dw*.25+.05,mx+dw*.25-.05,y+dh*.5-.06,y+dh*.5+.06,.1,frame)
				kit.slab(mx-.06,mx+.06,y,y+dh,.1,frame)
			return
		"vault":
			kit.slab(cx-dw*.5-.3,cx+dw*.5+.3,y,y+dh+.3,.06,Color(style.frame))
			kit.disc(Vector3(cx,y+dh*.5,.11),minf(dw,dh)*.5,col,12)
			kit.disc(Vector3(cx,y+dh*.5,.115),minf(dw,dh)*.18,col.darkened(.3),8)
			for k in range(3):
				var a=TAU*k/3.
				kit.slab(cx+cos(a)*.35-.04,cx+cos(a)*.35+.04,y+dh*.5+sin(a)*.35-.04,y+dh*.5+sin(a)*.35+.04,.14,Color("d8d0b8"))
			return
		"airlock":
			kit.slab(cx-dw*.5-.25,cx+dw*.5+.25,y,y+dh+.25,.06,Color(style.frame))
			kit.slab(cx-dw*.5,cx-.02,y,y+dh,.08,col);kit.slab(cx+.02,cx+dw*.5,y,y+dh,.08,col)
			kit.slab(cx-dw*.5-.25,cx+dw*.5+.25,y+dh+.05,y+dh+.2,.1,Color(style.trim))
			kit.box(Vector3(cx+dw*.5+.14,y+1.2,.1),Vector3(.12,.18,.06),Color("3fe07a"))
			return
		"archdoor","gate":
			var r=dw*.5
			kit.slab(cx-dw*.5-.14,cx+dw*.5+.14,y,y+dh-r,.06,frame)
			kit.arch_ring(cx,y+dh-r,.07,r,.14,frame)
			kit.slab(cx-dw*.5,cx+dw*.5,y,y+dh-r,.07,col)
			kit.arch(cx,y+dh-r,.075,r,col)
			for k in [-1,1]:kit.slab(cx+k*dw*.25-.03,cx+k*dw*.25+.03,y,y+dh-r,.09,col.darkened(.2))
			if kind=="gate":
				for k in range(3):kit.slab(cx-dw*.5,cx+dw*.5,y+.4+k*.8,y+.48+k*.8,.1,Color("3a3a3a"))
			return
	# Plain panel door with frame, panels and knob.
	kit.slab(cx-dw*.5-.1,cx+dw*.5+.1,y,y+dh+.1,.05,frame)
	kit.slab(cx-dw*.5,cx+dw*.5,y,y+dh,.07,col)
	kit.slab(cx-dw*.5+.12,cx+dw*.5-.12,y+dh*.55,y+dh-.15,.085,col.lightened(.08))
	kit.slab(cx-dw*.5+.12,cx+dw*.5-.12,y+.15,y+dh*.45,.085,col.lightened(.08))
	kit.box(Vector3(cx+dw*.5-.14,y+1.0,.1),Vector3(.06,.06,.05),Color("e0c070"))

static func awning(kit:Kit,cx:float,y:float,aw:float,colors:Array,depth:=.85):
	var a=Color(colors[0]);var b=Color(colors[1])
	var stripes=maxi(2,roundi(aw/.45))
	for k in range(stripes):
		var sx=cx-aw*.5+aw*k/stripes;var ex=aw/stripes
		var col=a if k%2==0 else b
		# Sloped canvas from the wall down and out.
		kit.quad4(kit.detail,Vector3(sx,y-.45,depth),Vector3(sx+ex,y-.45,depth),Vector3(sx+ex,y,.04),Vector3(sx,y,.04),col)
		kit.quad4(kit.detail,Vector3(sx,y-.62,depth),Vector3(sx+ex,y-.62,depth),Vector3(sx+ex,y-.45,depth),Vector3(sx,y-.45,depth),col.darkened(.1))
	# Side cheeks.
	for side in [cx-aw*.5,cx+aw*.5]:
		kit.quad4(kit.detail,Vector3(side,y-.45,.04),Vector3(side,y-.45,depth),Vector3(side,y,.04),Vector3(side,y,.04),a.darkened(.15))

static func ground_floor(kit:Kit,style:Dictionary,p:Dictionary,x0:float,x1:float,y0:float,y1:float,bays:int,hs:int,fixtures:Array):
	var level=maxf(y0,y1);var low=minf(y0,y1);var w=x1-x0
	var kind=str(style.ground)
	var near_deck=p.flags&4!=0
	var indoor=bool(style.get("indoor",false))
	if bays==0:return
	# Steep pieces: no doors (their sill would float); windows only.
	var steep=absf(y1-y0)>.35
	var door_bay=-1
	if not steep and w>=3.:door_bay=(hs/5)%bays if bays>1 else (0 if hs%2==0 else -1)
	if indoor:door_bay=-1 if hs%3 else door_bay
	for b in range(bays):
		var cx=x0+w*(b+.5)/bays
		var y=lerpf(y0,y1,(cx-x0)/w)
		if b==door_bay:
			match kind:
				"roller","dock":
					door(kit,style,cx,y,minf(3.,w/bays-.6),2.8,hs+b,"roller")
					if kind=="dock":
						for side in [-1,1]:kit.slab(cx+side*1.7-.12,cx+side*1.7+.12,y+.2,y+1.0,.1,Color("2a2a2a"))
				"barn":door(kit,style,cx,y,minf(2.6,w/bays-.4),2.5,hs+b,"barn")
				"vault":door(kit,style,cx,y,2.4,2.4,hs+b,"vault")
				"airlock":door(kit,style,cx,y,1.6,2.3,hs+b,"airlock")
				"archdoor","arcade","blindarch":door(kit,style,cx,y,1.3,2.6,hs+b,"archdoor")
				"gate":door(kit,style,cx,y,1.8,2.9,hs+b,"gate")
				"bunker":door(kit,style,cx,y,1.2,2.1,hs+b,"door");kit.slab(cx-1.,cx+1.,y+2.2,y+2.45,.12,Color(style.plinth[1]))
				"glass":door(kit,style,cx,y,1.4,2.2,hs+b,"airlock")
				_:door(kit,style,cx,y,1.15,2.15,hs+b,"door")
			var aw:Array=style.get("awnings",[])
			if not aw.is_empty() and not near_deck and kind!="shop":awning(kit,cx,y+2.95,1.9,pick(aw,hs+b),.8)
			if style.extras.has("lantern") and not near_deck:
				lantern(kit,cx+.95,y+2.35,fixtures,Color("ffd49a"))
			continue
		match kind:
			"shop":
				# Shop front: big glazing, sign board and a striped awning.
				var sw=minf(w/bays-.5,2.6)
				kit.slab(cx-sw*.5-.1,cx+sw*.5+.1,y+.3,y+2.4,.05,Color(style.frame))
				kit.quad(Vector3(cx-sw*.5,y+.5,.085),Vector3(sw,0,0),Vector3(0,1.75,0),Color(style.glass).lightened(.15))
				kit.slab(cx-.03,cx+.03,y+.5,y+2.25,.1,Color(style.frame))
				kit.slab(cx-sw*.5-.1,cx+sw*.5+.1,y+2.45,y+2.85,.08,Color(pick(["2f5f8a","8a3f2f","3f7a4a","8a6a2f"],hs+b)))
				var aw:Array=style.get("awnings",[])
				if not aw.is_empty() and not near_deck:awning(kit,cx,y+3.0,sw+.4,pick(aw,hs+b*3),.95)
				if style.extras.has("crates") and (hs+b)%2==0:
					for k in range(3):kit.box(Vector3(cx-sw*.3+k*.36,y+.19,.1),Vector3(.3,.38,.12),Color(["c9a36d","8fbf5a","e07a5f"][(hs+k)%3]))
			"arcade":
				# Blind arcade: arch recesses with dark shade.
				kit.slab(cx-1.,cx+1.,y,y+2.,.04,Color(style.trim).darkened(.35))
				kit.arch(cx,y+2.,.075,1.,Color(style.trim).darkened(.35))
				for k in [-1,1]:kit.slab(cx+k*1.1-.18,cx+k*1.1+.18,y,y+2.4,.1,Color(style.trim))
				kit.arch_ring(cx,y+2.,.08,1.,.14,Color(style.trim))
			"blindarch":
				kit.arch_ring(cx,y+1.9,.08,minf(1.2,w/bays*.4),.2,Color(style.trim))
				kit.slab(cx-minf(1.2,w/bays*.4)-.2,cx-minf(1.2,w/bays*.4),y,y+1.9,.08,Color(style.trim))
				kit.slab(cx+minf(1.2,w/bays*.4),cx+minf(1.2,w/bays*.4)+.2,y,y+1.9,.08,Color(style.trim))
			"glass":pass
			_:
				if not indoor and not steep:window(kit,style,cx,level,hs+b*5,near_deck)
				elif not indoor:window(kit,style,cx,level+.2,hs+b*5,near_deck)

static func roof_edge(kit:Kit,style:Dictionary,x0:float,x1:float,y:float,trim:Color,wall:Color,hs:int):
	match str(style.get("top","cornice")):
		"cornice":
			kit.slab(x0-.05,x1+.05,y-.3,y-.12,.12,trim)
			kit.slab(x0-.1,x1+.1,y-.12,y+.02,.22,trim.lightened(.05))
		"parapet":
			kit.slab(x0,x1,y-.25,y,.08,trim)
		"eave":
			var roof=Color(pick(["b5563e","8f4a3a","6a5a4a","4f6a7a"],hs))
			kit.quad4(kit.detail,Vector3(x0-.1,y-.35,.7),Vector3(x1+.1,y-.35,.7),Vector3(x1+.1,y,.03),Vector3(x0-.1,y,.03),roof)
			kit.slab(x0-.1,x1+.1,y-.45,y-.35,.7,roof.darkened(.2))
		"tiles":
			var roof=Color("b5634a")
			kit.quad4(kit.detail,Vector3(x0-.1,y-.25,.45),Vector3(x1+.1,y-.25,.45),Vector3(x1+.1,y+.05,.03),Vector3(x0-.1,y+.05,.03),roof)
			for k in range(int((x1-x0)/.4)):kit.slab(x0+k*.4,x0+k*.4+.06,y-.25,y+.05,.47,roof.darkened(.15))
		"balustrade":
			kit.slab(x0,x1,y-.3,y-.12,.14,trim)
			kit.slab(x0,x1,y+.55,y+.65,.12,trim,-.1)
			for k in range(int((x1-x0)/.3)):kit.slab(x0+.1+k*.3,x0+.2+k*.3,y-.12,y+.55,.08,trim,-.05)
		"crenel":
			kit.slab(x0,x1,y-.2,y,.1,trim)
			var n=maxi(1,roundi((x1-x0)/1.2))
			for k in range(n):
				if k%2==0:kit.slab(x0+(x1-x0)*k/n,x0+(x1-x0)*(k+1)/n,y,y+.7,.35,wall.darkened(.05),-.3)
		"steps":
			# Canal house stepped gable.
			var cx=(x0+x1)*.5;var hw=(x1-x0)*.5
			for k in range(3):
				var sw=hw*(1.-k*.28)
				kit.slab(cx-sw,cx+sw,y+k*.6,y+(k+1)*.6,.3,wall,-.27)
				kit.slab(cx-sw-.04,cx+sw+.04,y+(k+1)*.6-.08,y+(k+1)*.6,.36,trim,-.3)
			kit.slab(cx-.25,cx+.25,y+1.8,y+2.3,.3,wall,-.27);kit.slab(cx-.3,cx+.3,y+2.3,y+2.4,.36,trim,-.3)
		"round":
			kit.slab(x0,x1,y-.1,y+.25,.1,wall.darkened(.05))
			for k in range(int((x1-x0)/2.4)):kit.box(Vector3(x0+1.2+k*2.4,y-.5,.2),Vector3(.14,.14,.4),Color("7a5a3a"))
		"rail":
			kit.slab(x0,x1,y-.18,y,.08,trim)
			kit.slab(x0,x1,y+.95,y+1.02,.05,trim,-.2)
			for k in range(int((x1-x0)/1.5)+1):kit.slab(x0+k*1.5,x0+k*1.5+.05,y,y+.95,.05,trim,-.2)
		"jagged":
			var n=maxi(1,int((x1-x0)/1.4))
			for k in range(n):
				var h=[.0,.5,.2,.8,.35][(hs+k)%5]
				kit.slab(x0+(x1-x0)*k/n,x0+(x1-x0)*(k+1)/n,y-.15,y+h,.06,wall.darkened(.1+.05*(k%2)))

static func lantern(kit:Kit,x:float,y:float,fixtures:Array,light:Color):
	var dark=Color("34434a")
	kit.box(Vector3(x,y+.2,.08),Vector3(.1,.3,.1),dark)
	kit.box(Vector3(x,y+.3,.22),Vector3(.05,.05,.3),dark)
	kit.box(Vector3(x,y,.36),Vector3(.2,.3,.2),light)
	kit.box(Vector3(x,y+.17,.36),Vector3(.26,.05,.26),dark)
	if fixtures.size()<48:fixtures.append({"pos":kit.xf*Vector3(x,y-.1,.5),"direction":kit.xf.basis*Vector3(0,-1,.4),"color":light,"range":5.,"energy":1.4})

static func balcony(kit:Kit,cx:float,y:float,bw:float,trim:Color):
	# Slab + rail at the storey floor, entirely above head height.
	kit.slab(cx-bw*.5,cx+bw*.5,y-.1,y+.05,.8,trim)
	kit.slab(cx-bw*.5,cx+bw*.5,y+.9,y+.96,.05,Color("3a4046"),.72)
	for k in range(int(bw/.25)+1):kit.slab(cx-bw*.5+k*.25-.02,cx-bw*.5+k*.25+.02,y+.05,y+.9,.03,Color("3a4046"),.74)
	for side in [-1,1]:kit.slab(cx+side*bw*.5-.03,cx+side*bw*.5+.03,y+.05,y+.96,.8,Color("3a4046"))

static func banner(kit:Kit,cx:float,y:float,hs:int):
	var col=Color(["b53a3a","3a5ab5","c9a03a"][hs%3])
	kit.slab(cx-.55,cx+.55,y-2.,y,.04,col)
	kit.arch(cx,y-2.,.075,.55,col.darkened(.25))
	kit.slab(cx-.65,cx+.65,y-.05,y+.05,.12,Color("5a4a3a"))
	kit.disc(Vector3(cx,y-.9,.08),.28,Color("f0e0b0"),6)

static func shelf(kit:Kit,cx:float,y:float,wood:Color,hs:int):
	kit.slab(cx-.8,cx+.8,y,y+2.0,.1,wood)
	for r in range(4):
		var ry=y+.15+r*.48
		kit.slab(cx-.75,cx+.75,ry,ry+.04,.11,wood.lightened(.1))
		var bx=cx-.72
		var k=0
		while bx<cx+.68:
			var bw=[.06,.09,.07,.1,.05][(hs+r*3+k)%5]
			kit.quad(Vector3(bx,ry+.04,.105),Vector3(bw,0,0),Vector3(0,[.34,.3,.38,.28][(hs+k+r)%4],0),Color(["a33a3a","3a5a8a","3a7a4a","c9a03a","6a4a8a","2f2f2f","d8cbb0"][(hs*3+r*5+k)%7]))
			bx+=bw+.01;k+=1

## Interior (full height) wall dressing for indoor maps.
static func interior(kit:Kit,style:Dictionary,p:Dictionary,x0:float,x1:float,y0:float,y1:float,level:float,top:float,hs:int,fixtures:Array):
	var w=x1-x0;var trim=Color(style.trim);var frame=Color(style.frame)
	var bays=maxi(1,floori(w/float(style.spacing)))
	# Clerestory windows / high glazing.
	var kind=str(style.win[0])
	if kind!="none" and w>1.6:
		for b in range(bays):
			var cx=x0+w*(b+.5)/bays
			if kind=="band":continue
			if kind=="arch" and style.extras.has("books"):
				window(kit,style,cx,level+2.4,hs+b,false)
			else:
				window(kit,style,cx,level,hs+b,false)
	if kind=="band" and w>1.2:
		var yb=level+float(style.win[3]);var h=float(style.win[2])
		kit.slab(x0+.2,x1-.2,yb-.1,yb+h+.1,.05,frame)
		kit.quad(Vector3(x0+.3,yb,.085),Vector3(w-.6,0,0),Vector3(0,h,0),Color(style.glass))
		for k in range(int((w-.6)/1.4)+1):kit.slab(x0+.3+k*1.4-.03,x0+.3+k*1.4+.03,yb,yb+h,.1,frame)
	# Top trim at the ceiling line.
	kit.slab(x0,x1,minf(y0,y1)+top-.25,minf(y0,y1)+top,.08,trim.darkened(.1))

## Themed ornaments.
static func extras(kit:Kit,style:Dictionary,p:Dictionary,x0:float,x1:float,y0:float,y1:float,level:float,crown:float,hs:int,fixtures:Array):
	var w=x1-x0;var list:Array=style.extras;var trim=Color(style.trim);var frame=Color(style.frame)
	var indoor=bool(style.get("indoor",false));var near_deck=p.flags&4!=0
	var low=minf(y0,y1);var top:float=p.top
	var storey:float=p.storey
	var floors=maxi(1,floori((top-p.from)/storey+.01))
	# Continuous window bands (industrial) per upper storey.
	if str(style.win[0])=="band" and not indoor and w>2.:
		for s in range(1 if p.from<=0. else 0,floors):
			var yb=level+p.from+s*storey+.9;var h=float(style.win[2])
			kit.slab(x0+.3,x1-.3,yb-.08,yb+h+.08,.05,frame)
			kit.quad(Vector3(x0+.4,yb,.085),Vector3(w-.8,0,0),Vector3(0,h,0),Color(style.glass))
			for k in range(int((w-.8)/1.2)+1):kit.slab(x0+.4+k*1.2-.03,x0+.4+k*1.2+.03,yb,yb+h,.1,frame)
	if str(style.win[0])=="grid" and w>1.:
		# Greenhouse: the whole wall is glazing on a white frame grid.
		var yb=level+float(style.win[3]);var yt=low+top-.2
		kit.quad(Vector3(x0+.1,yb,.07),Vector3(w-.2,0,0),Vector3(0,yt-yb,0),Color(style.glass))
		var cols=maxi(1,int(w/1.4))
		for k in range(cols+1):kit.slab(x0+.1+(w-.2)*k/cols-.04,x0+.1+(w-.2)*k/cols+.04,yb,yt,.1,frame)
		var y=yb
		while y<yt:kit.slab(x0+.1,x1-.1,y-.03,y+.03,.1,frame);y+=1.1
	for e in list:
		match e:
			"drain":
				kit.slab(x0+.15,x0+.27,low,low+crown-.2,.1,Color("8a9296"))
				kit.slab(x0+.1,x0+.32,low+crown-.35,low+crown-.2,.14,Color("8a9296"))
			"pilasters":
				for x in [x0+.25,x1-.25]:kit.slab(x-.18,x+.18,low,low+crown-.3,.08,trim)
			"ribs":
				var x=x0+.3
				while x<x1-.2:
					kit.slab(x-.04,x+.04,low+.4,low+top-.3,.04,Color(pick(style.colors,hs)).darkened(.12))
					x+=.6
			"hazard":
				if p.from<=0.:
					var n=int(w/.5)
					for k in range(n):kit.slab(x0+k*.5,x0+k*.5+.5,low+.05,low+.35,.07,Color("f0c23f") if k%2==0 else Color("2a2a2a"))
			"numbers":
				if hs%2==0 and w>3.:
					var nx=(x0+x1)*.5;var ny=low+top-1.6
					kit.slab(nx-.7,nx+.7,ny-.6,ny+.6,.04,Color("f4f1e8"))
					var digit=hs%10
					kit.slab(nx-.35,nx+.35,ny+.3,ny+.42,.07,Color("2a2f33"))
					kit.slab(nx-.06,nx+.06,ny-.42,ny+.42,.07,Color("2a2f33"))
					if digit%2:kit.slab(nx-.35,nx+.35,ny-.42,ny-.3,.07,Color("2a2f33"))
			"lifebuoy":
				if hs%4==0 and not near_deck:
					kit.disc(Vector3(x1-.8,low+1.6,.08),.35,Color("e8523f"),10)
					kit.disc(Vector3(x1-.8,low+1.6,.085),.18,Color(pick(style.colors,hs)),8)
			"girders":
				for x in [x0+.2,x1-.2]:kit.slab(x-.15,x+.15,low,low+top,.12,Color("5a6570"))
				for s in range(1,floors+1):kit.slab(x0,x1,low+s*storey-.2 if not indoor else low+top-.5,low+s*storey if not indoor else low+top-.3,.1,Color("5a6570"))
			"pipes":
				var py=low+(2.6 if not indoor else 3.8)
				kit.slab(x0,x1,py,py+.22,.2,Color("8a6a4a") if style.has("indoor") else Color("9aa4a8"),.02)
				if hs%2==0:kit.slab(x1-.8,x1-.58,low+.3,low+top-.3,.2,Color("b05a3a"),.02)
				if indoor:kit.slab(x0,x1,py+.5,py+.66,.18,Color("4f7a8a"),.02)
			"vents":
				if hs%2==1 and w>2.:
					var vx=x0+w*.3;var vy=low+(top-1.4 if not indoor else 4.4)
					kit.slab(vx-.4,vx+.4,vy-.3,vy+.3,.06,Color("9aa4a8"))
					for k in range(4):kit.slab(vx-.35,vx+.35,vy-.24+k*.15,vy-.2+k*.15,.09,Color("6a7478"))
			"stripe":
				sloped_band(kit,x0,x1,y0,y1,1.1,1.3,.02,trim)
			"trefoil":
				if hs%3==0 and w>2.:
					var c=Vector3((x0+x1)*.5,low+2.,.07)
					kit.disc(c,.45,Color("f0c23f"),3)
					kit.disc(c+Vector3(0,0,.005),.1,Color("2a2a2a"),6)
			"signs":
				if hs%2==0 and w>2. and not near_deck:
					var sx=x1-.5;var sy=low+3.9
					kit.slab(sx-.05,sx+.05,sy+.3,sy+.4,.6,Color("3a3a3a"))
					kit.box(Vector3(sx,sy,.55),Vector3(.08,.8,.55),Color(pick(["d24c3f","2f7fbf","e0a02f","2f9a6a"],hs)))
			"clock":
				if w>6. and hs%3==0:
					var c=Vector3((x0+x1)*.5,low+crown-1.2,.12)
					kit.disc(c,.75,trim,12);kit.disc(c+Vector3(0,0,.01),.62,Color("f8f4e8"),12)
					kit.slab(c.x-.03,c.x+.03,c.y,c.y+.45,.15,Color("2a2a2a"));kit.slab(c.x,c.x+.35,c.y-.03,c.y+.03,.15,Color("2a2a2a"))
			"buttress":
				for x in [x0+.35,x1-.35]:
					kit.slab(x-.25,x+.25,low,low+2.,.14,Color(style.plinth[1]))
					kit.slab(x-.2,x+.2,low+2.,low+minf(top,5.),.1,Color(style.plinth[1]).lightened(.05))
			"ivy":
				if hs%3==0:
					for k in range(5):
						var ix=x0+.4+((hs+k*37)%100)/100.*maxf(.2,w-.8);var iy=low+.3+k*.55
						kit.box(Vector3(ix,iy,.08),Vector3(.5+.1*(k%3),.45,.1),Color(["5f8f4a","4f7f3f","6f9f55"][k%3]))
			"torches":
				if hs%2==0 and not near_deck:lantern(kit,x0+.7,low+2.4,fixtures,Color("ffb35a"))
			"bell":
				if hs%5==0 and w>3.:
					kit.arch_ring((x0+x1)*.5,low+crown-.8,.1,.45,.12,trim)
					kit.disc(Vector3((x0+x1)*.5,low+crown-1.,.12),.25,Color("c9a03a"),8)
			"hoist":
				kit.slab((x0+x1)*.5-.06,(x0+x1)*.5+.06,low+crown-.3,low+crown-.18,.7,Color("3a2f28"))
				kit.box(Vector3((x0+x1)*.5,low+crown-.45,.66),Vector3(.12,.2,.12),Color("3a3a3a"))
			"beams":
				var wood=Color("5a3f2a")
				for s in range(1,floors):kit.slab(x0,x1,low+s*storey-.12,low+s*storey+.1,.08,wood)
				for x in [x0+.12,x1-.12]:kit.slab(x-.12,x+.12,low,low+top,.08,wood)
				if w>3. and floors>1:
					kit.slab((x0+x1)*.5-.1,(x0+x1)*.5+.1,low+storey,low+top,.07,wood)
			"shoring":
				if hs%2==0 and w>3.:
					var wood=Color("7a5a3a")
					for k in range(2):kit.slab(x0+1.+k*(w-2.),x0+1.2+k*(w-2.),low,low+2.3,.1,wood)
					kit.slab(x0+.9,x1-.9,low+2.2,low+2.4,.1,wood)
			"hay":
				if hs%2==1 and w>2.5 and not near_deck:
					var hx=(x0+x1)*.5
					kit.slab(hx-.7,hx+.7,low+top-2.4,low+top-1.1,.05,Color("5a3a2a"))
					kit.box(Vector3(hx-.3,low+top-2.2,.25),Vector3(.5,.35,.35),Color("e0c070"))
			"sandbags":
				if p.from<=0. and hs%2==0:
					var sb=Color("b8a47a")
					for r in range(2):
						var k=0;var x=x0+.2+r*.25
						while x<x1-.5:
							kit.box(Vector3(x+.25,low+.12+r*.22,.07),Vector3(.48,.22,.1),sb.darkened(.05*((k+r)%2)));x+=.52;k+=1
			"camo":
				if hs%3==0:
					for k in range(4):kit.quad(Vector3(x0+.5+k*w/4.,low+1.+(k%2)*1.3,.035),Vector3(minf(1.4,w/4.),0,0),Vector3(0,.8,0),Color(["8a8f5a","a89a6a","6f7a4a","b5a06a"][(hs+k)%4]))
			"antenna":
				if hs%4==0:
					kit.slab(x1-.6,x1-.54,low+top,low+top+2.5,.06,Color("5a5f60"),-.3)
					kit.disc(Vector3(x1-.57,low+top+2.5,-.2),.12,Color("e05a3a"),6)
			"rust":
				for k in range(3):
					var rx=x0+((hs*7+k*31)%100)/100.*maxf(.5,w-1.2);var ry=low+.4+((hs+k*13)%5)*.7
					kit.quad(Vector3(rx,ry,.036),Vector3(.9,0,0),Vector3(0,1.1,0),Color(["9a5a32","7a4a2a","a8683a"][k%3]))
			"targets":
				if hs%2==0 and w>2.4:
					var c=Vector3((x0+x1)*.5,low+1.5,.08)
					kit.disc(c,.55,Color("f4f1e8"),12);kit.disc(c+Vector3(0,0,.005),.4,Color("e05a3a"),12);kit.disc(c+Vector3(0,0,.01),.2,Color("f4f1e8"),10);kit.disc(c+Vector3(0,0,.015),.08,Color("e05a3a"),8)
			"planters":
				if p.from<=0.:kit.slab(x0+.1,x1-.1,low,low+.5,.12,Color("8a6a4a"))
			"vines":
				if hs%2==0:
					for k in range(4):kit.box(Vector3(x0+.3+k*(w-.6)/4.,low+.62,.1),Vector3(.35,.25,.1),Color("5f9f4a"))
			"pots":
				if hs%3==1 and p.from<=0. and not near_deck:
					for k in range(2):
						var px=x0+.6+k*(w-1.2)
						kit.box(Vector3(px,low+.2,.08),Vector3(.32,.4,.1),Color("b5634a"))
						kit.box(Vector3(px,low+.5,.09),Vector3(.4,.25,.1),Color("5f9f4a"))
			# Interiors.
			"books":
				var x=x0+.3
				while x+1.6<x1-.2:
					shelf(kit,x+.8,level,frame,hs+int(x*3.))
					x+=1.8
			"racks":
				var x=x0+.3
				while x+.7<x1-.2:
					kit.slab(x,x+.66,level,level+2.1,.14,Color("2a3036"))
					for r in range(8):
						var ry=level+.2+r*.23
						kit.slab(x+.05,x+.61,ry,ry+.16,.15,Color("3a424a"))
						kit.box(Vector3(x+.52,ry+.08,.155),Vector3(.04,.04,.01),Color(["3fe07a","2fb8e0","3fe07a","f0c23f"][(hs+r+int(x))%4]))
					x+=.72
			"cable_tray":
				kit.slab(x0,x1,level+2.6,level+2.7,.3,Color("8a949c"))
			"lockers":
				if hs%2==0 and w>2.:
					for k in range(int(minf(w-1.,3.)/.5)):
						var lx=x0+.5+k*.5
						kit.slab(lx,lx+.48,level,level+1.9,.1,Color("4f7a9a"))
						kit.slab(lx+.1,lx+.38,level+1.6,level+1.65,.11,Color("2a3a4a"))
			"toolboards":
				if hs%2==1 and w>2.:
					var tx=x0+w*.5
					kit.slab(tx-.9,tx+.9,level+1.2,level+2.2,.03,Color("c8a878"))
					for k in range(5):kit.slab(tx-.75+k*.35,tx-.7+k*.35,level+1.4,level+2.,.07,Color(["c93f3f","3f5fc9","3a3a3a","c9a03a","3a3a3a"][k]))
			"gauges":
				if hs%2==0:
					for k in range(3):
						var c=Vector3(x0+.8+k*.7,level+1.6,.06)
						kit.disc(c,.2,Color("f4f1e8"),10);kit.slab(c.x-.01,c.x+.12,c.y-.01,c.y+.01,.09,Color("c93f3f"))
			"cabinets":
				if hs%3==0 and w>2.:
					kit.slab(x1-1.6,x1-.4,level,level+1.8,.12,Color("b8c4c8"))
					kit.slab(x1-1.0,x1-.99,level+.1,level+1.7,.13,Color("7a8a90"))
			"wainscot":
				sloped_band(kit,x0,x1,y0,y1,0.,1.1,.03,Color("8a6f55"))
				sloped_band(kit,x0,x1,y0,y1,1.1,1.16,.05,Color("6a543f"))
			"plants":
				if hs%3==0:
					kit.box(Vector3(x0+.5,level+.3,.08),Vector3(.4,.6,.1),Color("d8d0c0"))
					kit.box(Vector3(x0+.5,level+.9,.09),Vector3(.55,.7,.1),Color("5f9f4a"))
			"artwork":
				if hs%2==1 and w>2.:
					var ax=(x0+x1)*.5
					kit.slab(ax-.7,ax+.7,level+1.4,level+2.3,.04,Color("3a3a3a"))
					kit.quad(Vector3(ax-.6,level+1.5,.075),Vector3(1.2,0,0),Vector3(0,.7,0),Color(pick(["e0a05a","5a8ac9","c95a7a","6ab58a"],hs)))
			"lamps":
				if hs%2==0:lantern(kit,x0+.5,level+2.5,fixtures,Color("ffdca0"))
			"rivets":
				var y=level+.6
				while y<low+top-.4:
					var x=x0+.3
					while x<x1-.2:kit.box(Vector3(x,y,.04),Vector3(.05,.05,.02),Color("b8c0c6"));x+=.9
					y+=1.2
			"deposit":
				if hs%2==0 and w>2.:
					for r in range(4):
						for c in range(int(minf(w-1.,4.)/.4)):
							kit.slab(x0+.5+c*.4,x0+.87+c*.4,level+.6+r*.35,level+.92+r*.35,.05,Color("c9b27a"))
			"tyres":
				if hs%2==0 and w>2.:
					for k in range(3):
						kit.prism(Vector3(x1-.8,level+k*.26,.45),.38,.24,Color("2a2d30"),10)
			"oil":
				if hs%3==0:kit.quad4(kit.detail,Vector3(x0+.6,level+.02,1.4),Vector3(x0+2.,level+.02,1.4),Vector3(x0+2.,level+.02,.3),Vector3(x0+.6,level+.02,.3),Color("3a3f44"))
			"bigpipes":
				for k in range(2):
					var py=level+4.4+k*.9
					kit.slab(x0,x1,py,py+.5,.45,Color(["c9a03a","4f8a9a"][k]),.02)
					for x in [x0+.5,x1-.5]:kit.slab(x-.3,x+.3,py-.08,py+.58,.5,Color("5a6268"),.02)
			"warning":
				if hs%2==1 and w>2.:
					var c=Vector3((x0+x1)*.5,level+2.2,.07)
					kit.disc(c,.4,Color("f0c23f"),3);kit.slab(c.x-.03,c.x+.03,c.y-.12,c.y+.15,.08,Color("2a2a2a"))
			"biohazard":
				if hs%3==0 and w>2.:
					var c=Vector3((x0+x1)*.5,level+2.6,.07)
					kit.disc(c,.45,Color("e07a2f"),12);kit.disc(c+Vector3(0,0,.005),.2,Color("f2f2ea"),8);kit.disc(c+Vector3(0,0,.01),.08,Color("e07a2f"),6)
			"vaultdoor":
				if hs%4==1 and w>4.:
					var c=Vector3((x0+x1)*.5,level+1.5,.08)
					kit.disc(c,1.45,Color("5a6268"),16);kit.disc(c+Vector3(0,0,.01),1.25,Color("b8a060"),16);kit.disc(c+Vector3(0,0,.02),.35,Color("8a949c"),10)
					for k in range(6):
						var a=TAU*k/6.
						kit.slab(c.x+cos(a)*.9-.07,c.x+cos(a)*.9+.07,c.y+sin(a)*.9-.07,c.y+sin(a)*.9+.07,.14,Color("d8d0b8"))
			"graffiti":
				if hs%3==0 and w>3.:
					for k in range(3):kit.quad(Vector3(x0+.8+k*.7,level+.6+(k%2)*.3,.036),Vector3(.8,0,0),Vector3(0,.6,0),Color(["e05aa0","3fb8e0","f0c23f"][k]))
