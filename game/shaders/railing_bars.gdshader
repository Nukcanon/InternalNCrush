// 1.4.10: the vertical bars of a deep-water railing, drawn on one panel per run
// (UV.x: metres along the run, UV.y: metres up) - only the bars are kept, the gaps
// between them are cut out. One quad per run instead of a mesh per bar (the map
// caches stay small; headless bakes keep no MultiMesh data).
shader_type spatial;
render_mode cull_disabled;
uniform vec4 bar_color : source_color = vec4(0.29, 0.32, 0.34, 1.0);
uniform float spacing = 0.13;
uniform float width = 0.028;
void fragment() {
	float f = fract(UV.x / spacing) - 0.5;
	if (abs(f) * spacing > width * 0.5) discard;
	// a little shading across each bar so it reads round
	float across = abs(f) * spacing / (width * 0.5);
	ALBEDO = bar_color.rgb * (1.0 - 0.35 * across * across);
	ROUGHNESS = 0.55;
	METALLIC = 0.35;
}
