class_name UiSkin
extends RefCounted
## 1.4 cartoon menu skin: cream paper panels with a thick ink outline and a drop
## shadow, chunky rounded buttons with a raised bottom edge, bold flat colours.
## Menus, lobbies and dialogs use this theme; the in-match HUD keeps its own
## translucent dark theme for readability over the game.
const INK=Color("2b2f3a")
const PAPER=Color("fff6e6")
const PAPER_DEEP=Color("f1e2c6")
const CARD_A=Color("ffffff")
const CARD_B=Color("fcefd6")
const MUTED=Color("6f6a5e")
const ACCENT=Color("2f7fd8")
const GOLD=Color("b87800")
const PRIMARY=Color("ffc53d")
const NEUTRAL=Color("ffffff")
const GO=Color("5cc98a")
const STOP=Color("ff7a6b")
const BLUE=Color("4ea4ff")
const ORANGE=Color("ff9a3c")
const DISABLED=Color("ddd5c4")
const KINDS={"primary":PRIMARY,"neutral":NEUTRAL,"go":GO,"stop":STOP,"blue":BLUE,"orange":ORANGE}
static func box(bg:Color,border:=INK,width:=3,bottom:=3,radius:=14,margin:=Vector4(16,10,16,10)) -> StyleBoxFlat:
	var s=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(width);s.border_width_bottom=bottom
	s.set_corner_radius_all(radius);s.anti_aliasing=true
	s.content_margin_left=margin.x;s.content_margin_top=margin.y;s.content_margin_right=margin.z;s.content_margin_bottom=margin.w
	return s
## Raised button faces: the thick bottom edge sinks when pressed.
static func faces(bg:Color,touch:=false) -> Dictionary:
	var pad=Vector4(16,9,16,8) if not touch else Vector4(20,12,20,11)
	var normal=box(bg,INK,3,7,14,pad)
	var hover=box(bg.lightened(.18),INK,3,7,14,pad)
	var pressed=box(bg.darkened(.08),INK,3,3,14,Vector4(pad.x,pad.y+4,pad.z,pad.w))
	var focus=box(Color(0,0,0,0),ACCENT,3,3,16,pad);focus.draw_center=false
	var disabled=box(DISABLED,Color("a39c8c"),3,5,14,pad)
	return {"normal":normal,"hover":hover,"pressed":pressed,"hover_pressed":pressed,"focus":focus,"disabled":disabled}
static func paint(button:Button,kind:String):
	var styles=faces(KINDS.get(kind,NEUTRAL))
	for state in styles:button.add_theme_stylebox_override(state,styles[state])
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
		button.add_theme_color_override(key,Color.WHITE if kind in ["stop","blue","go"] else INK)
	button.add_theme_color_override("font_disabled_color",Color("8c8676"))
## Alternating list cards (rooms, players).
static func card(index:int,margin:=10) -> StyleBoxFlat:
	return box(CARD_A if index%2==0 else CARD_B,Color("d8c7a6"),2,4,12,Vector4(margin,margin*.6,margin,margin*.6))
static func build(font:Font,touch:bool) -> Theme:
	var theme=Theme.new();theme.default_font=font;theme.default_font_size=28 if touch else 20
	# Panels and windows.
	var paper=box(PAPER,INK,4,4,24,Vector4(22,16,22,16));paper.shadow_color=Color(.1,.08,.05,.45);paper.shadow_size=3;paper.shadow_offset=Vector2(0,10)
	theme.set_stylebox("panel","PanelContainer",paper)
	for type in ["AcceptDialog","ConfirmationDialog"]:theme.set_stylebox("panel",type,box(PAPER,PAPER,0,0,0,Vector4(18,14,18,14)))
	var window=box(PAPER,INK,4,4,20,Vector4(8,40,8,8));window.expand_margin_top=36;window.shadow_color=Color(.1,.08,.05,.45);window.shadow_size=3;window.shadow_offset=Vector2(0,8)
	theme.set_stylebox("embedded_border","Window",window);theme.set_stylebox("embedded_unfocused_border","Window",window)
	theme.set_color("title_color","Window",INK);theme.set_font_size("title_font_size","Window",20)
	# Text.
	for type in ["Label","RichTextLabel"]:theme.set_color("font_color" if type=="Label" else "default_color",type,INK)
	theme.set_constant("outline_size","Label",0)
	# Buttons (neutral by default; UI code paints primary/back/team variants).
	var styles=faces(NEUTRAL,touch)
	for state in styles:theme.set_stylebox(state,"Button",styles[state])
	# Selected toggles (cards, tabs) show the primary colour.
	var chosen=faces(PRIMARY,touch)
	theme.set_stylebox("pressed","Button",chosen.pressed);theme.set_stylebox("hover_pressed","Button",chosen.pressed)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:theme.set_color(key,"Button",INK)
	theme.set_color("font_disabled_color","Button",Color("8c8676"))
	# Inputs and dropdowns.
	var field=box(NEUTRAL,INK,3,3,12,Vector4(14,8,14,8));var field_focus=box(NEUTRAL,ACCENT,3,3,12,Vector4(14,8,14,8))
	for type in ["LineEdit","SpinBox"]:
		theme.set_stylebox("normal",type,field);theme.set_stylebox("focus",type,field_focus);theme.set_stylebox("read_only",type,box(PAPER_DEEP,Color("a39c8c"),3,3,12))
		theme.set_color("font_color",type,INK);theme.set_color("font_placeholder_color",type,Color("a09a8b"));theme.set_color("caret_color",type,INK)
		theme.set_color("selection_color",type,Color(ACCENT,.3))
	var option=faces(NEUTRAL,touch)
	for state in option:theme.set_stylebox(state,"OptionButton",option[state])
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:theme.set_color(key,"OptionButton",INK)
	theme.set_color("font_disabled_color","OptionButton",Color("8c8676"))
	theme.set_icon("arrow","OptionButton",arrow_icon())
	var popup=box(PAPER,INK,3,3,12,Vector4(6,6,6,6))
	theme.set_stylebox("panel","PopupMenu",popup);theme.set_stylebox("hover","PopupMenu",box(PRIMARY,PRIMARY,0,0,8,Vector4(8,4,8,4)))
	theme.set_color("font_color","PopupMenu",INK);theme.set_color("font_hover_color","PopupMenu",INK)
	# Check boxes.
	for selected in [false,true]:
		var mark='<path d="M7 12.5l3.5 3.5 7-8" fill="none" stroke="#2b2f3a" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>' if selected else ''
		var svg='<svg xmlns="http://www.w3.org/2000/svg" width="26" height="26"><rect x="2" y="2" width="22" height="22" rx="6" fill="'+("#ffc53d" if selected else "#ffffff")+'" stroke="#2b2f3a" stroke-width="3"/>'+mark+'</svg>'
		var image=Image.new();image.load_svg_from_string(svg);var texture=ImageTexture.create_from_image(image)
		for key in (["checked","checked_disabled"] if selected else ["unchecked","unchecked_disabled"]):theme.set_icon(key,"CheckBox",texture)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:theme.set_color(key,"CheckBox",INK)
	# Tabs.
	theme.set_stylebox("panel","TabContainer",box(CARD_A,INK,3,3,16,Vector4(10,10,10,10)))
	theme.set_stylebox("tab_selected","TabContainer",box(PRIMARY,INK,3,0,12,Vector4(18,8,18,8)))
	theme.set_stylebox("tab_unselected","TabContainer",box(PAPER_DEEP,INK,3,0,12,Vector4(18,8,18,8)))
	theme.set_stylebox("tab_hovered","TabContainer",box(PRIMARY.lightened(.35),INK,3,0,12,Vector4(18,8,18,8)))
	for key in ["font_selected_color","font_unselected_color","font_hovered_color"]:theme.set_color(key,"TabContainer",INK)
	# Scrolling and separators.
	var track=box(PAPER_DEEP,PAPER_DEEP,0,0,8,Vector4(6 if not touch else 10,0,6 if not touch else 10,0))
	var grab=box(Color("b9ab8e"),Color("b9ab8e"),0,0,8,Vector4(0,20,0,20))
	theme.set_stylebox("scroll","VScrollBar",track)
	for state in ["grabber","grabber_highlight","grabber_pressed"]:theme.set_stylebox(state,"VScrollBar",grab if state=="grabber" else box(Color("8f8268"),Color("8f8268"),0,0,8,Vector4(0,20,0,20)))
	theme.set_constant("h_separation","ScrollContainer",18)
	var line=StyleBoxLine.new();line.color=Color("e3d2b0");line.thickness=3
	theme.set_stylebox("separator","HSeparator",line);theme.set_constant("separation","HSeparator",14)
	# Tooltips and progress.
	theme.set_stylebox("panel","TooltipPanel",box(INK,INK,0,0,8,Vector4(10,6,10,6)));theme.set_color("font_color","TooltipLabel",PAPER)
	theme.set_stylebox("background","ProgressBar",box(PAPER_DEEP,INK,2,2,8,Vector4.ZERO));theme.set_stylebox("fill","ProgressBar",box(GO,INK,2,2,8,Vector4.ZERO))
	return theme
static func arrow_icon() -> Texture2D:
	var image=Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="18" height="12"><path d="M2 2l7 7 7-7" fill="none" stroke="#2b2f3a" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/></svg>')
	return ImageTexture.create_from_image(image)
## Main-menu logo: big white letters, thick ink outline, coloured drop layer.
static func logo(parent:Control,text:String,pos:Vector2,size:=72) -> Control:
	var holder=Control.new();holder.position=pos;parent.add_child(holder)
	for layer in [[Vector2(0,9),Color("ff9a3c"),0],[Vector2.ZERO,Color.WHITE,14]]:
		var l=Label.new();l.text=text;l.position=layer[0];l.add_theme_font_size_override("font_size",size)
		l.add_theme_color_override("font_color",layer[1]);l.add_theme_color_override("font_outline_color",INK);l.add_theme_constant_override("outline_size",16)
		l.add_theme_constant_override("line_spacing",-14);holder.add_child(l)
	return holder
