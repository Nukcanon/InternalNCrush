// Inverted-hull ink outline. Only attached on the high graphics preset.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;
uniform vec4 ink : source_color = vec4(0.10, 0.11, 0.16, 1.0);
uniform float width = 0.012;
void vertex() {
	VERTEX += NORMAL * width;
}
void fragment() {
	ALBEDO = ink.rgb;
}
