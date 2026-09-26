extends Control
## Twelve full-HD pre-rendered battle views. No world, bots or 3D viewport on Web menus.
const COUNT=12
var frames:Array[String]=[]
var layers:Array[TextureRect]=[]
var index=0
var elapsed=0.
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for i in range(COUNT):
		var path="res://assets/menu_slides/%02d.jpg"%(i+1)
		if ResourceLoader.exists(path):frames.append(path)
	frames.shuffle()
	for i in range(2):
		var layer=TextureRect.new();layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;layer.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(layer);layers.append(layer)
	if not frames.is_empty():
		layers[0].texture=load(frames[0]);layers[1].texture=load(frames[1%frames.size()]);layers[1].modulate.a=0.
func _process(dt:float):
	if frames.size()<2 or not is_visible_in_tree():return
	elapsed+=dt
	# Three seconds per image, including a short crossfade.
	layers[1].modulate.a=clampf((elapsed-2.65)/.35,0.,1.)
	if elapsed>=3.:
		elapsed=0.;index=(index+1)%frames.size()
		if index==0:
			var previous=frames[0];frames.shuffle()
			if frames[0]!=previous:
				var next_index=frames.find(previous);var first=frames[0];frames[0]=previous;frames[next_index]=first
		layers[0].texture=layers[1].texture;layers[1].texture=load(frames[(index+1)%frames.size()]);layers[1].modulate.a=0.
