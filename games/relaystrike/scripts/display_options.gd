extends RefCounted
class_name DisplayOptions
static func resolutions_for(native:Vector2i) -> Array:
	var choices=[]
	for size in [Vector2i(960,540),Vector2i(1024,768),Vector2i(1280,720),Vector2i(1280,800),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(1920,1200),Vector2i(2560,1080),Vector2i(2560,1440),Vector2i(2560,1600),Vector2i(3440,1440),Vector2i(3840,1600),Vector2i(3840,2160),Vector2i(5120,1440),Vector2i(5120,2880),Vector2i(7680,2160),Vector2i(7680,4320)]:
		if size.x<=native.x and size.y<=native.y:choices.append(size)
	if not native in choices:choices.append(native)
	choices.sort_custom(func(a,b):return a.x*a.y<b.x*b.y)
	return choices
