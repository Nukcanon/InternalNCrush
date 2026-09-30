extends SceneTree
# Which font renders each character of mixed captions, and the line metrics
# (1.4.2 caption centring). Args: "override" sets Hangul script support on Symbols.
func _initialize():call_deferred("run")
func run():
	var names=["res://assets/fonts/DoHyeon-Regular.ttf","res://assets/fonts/Symbols.ttf","res://assets/Korean.ttf"]
	var fonts=[]
	for n in names:
		var f:FontFile=load(n);fonts.append(f)
		print("FONT ",n.get_file()," ascent=",f.get_ascent(20)," descent=",f.get_descent(20)," scripts=",f.get_script_support_overrides()," langs=",f.get_language_support_overrides())
	if "override" in OS.get_cmdline_user_args():
		fonts[1].set_script_support_override("Hang",true);fonts[1].set_language_support_override("ko",true);print("OVERRIDE")
	var menu=FontVariation.new();menu.base_font=fonts[0];menu.fallbacks=[fonts[1],fonts[2]]
	var ts=TextServerManager.get_primary_interface()
	for text in ["병과 · 무기","1 · 2","· 가"]:
		var line=TextLine.new();line.add_string(text,menu,20)
		var owners=[]
		for glyph in ts.shaped_text_get_glyphs(line.get_rid()):
			var rid=glyph.font_rid;var who="?"
			for i in range(fonts.size()):
				if rid in fonts[i].get_rids():who=names[i].get_file().left(6)
			owners.append(who)
		print("LINE '",text,"' ascent=",line.get_line_ascent()," fonts=",owners)
	quit()
