// Inverted-hull ink outline with a constant on-screen width.
// 1.4.6 (the user: thin, and the line must run on smoothly): the hull is
// extruded along welded (smoothed) normals stored in TANGENT, in the view
// plane, by a width measured in pixels (scaled with the screen height), and
// pushed a little behind the body so it never z-fights into a dotted line.
// Normal depth test: never seen through walls. The colour changes with state
// (a marked target, HeroStyle.with_ink).
// 1.5.1 (the user: far away people's outlines stood out more - the line keeps its
// pixel width while the body gets small): with distance the dark ink fades toward
// a soft grey and the line thins a little (not below a pixel - thinner lines break
// up and shimmer). Coloured ink (a marked target) keeps its colour.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;
uniform vec4 ink : source_color = vec4(0.10, 0.11, 0.16, 1.0);
uniform vec4 ink_far : source_color = vec4(0.40, 0.42, 0.48, 1.0);
uniform float width_px = 1.1;
uniform float max_world = 0.009;
uniform float fade_near = 8.0;
uniform float fade_far = 30.0;
varying float far_fade;
void vertex() {
	vec3 smooth_n = TANGENT.xyz;
	if (dot(smooth_n, smooth_n) < 0.0001) smooth_n = NORMAL;
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_n = normalize(MODELVIEW_NORMAL_MATRIX * smooth_n);
	// world size of one pixel at this depth (1.5.0: an orthographic camera - the
	// gear screen previews and thumbnails - has no depth term; with it the line
	// came out several times too thick there)
	bool ortho = PROJECTION_MATRIX[3][3] > 0.5;
	float pixel = 2.0 * (ortho ? 1.0 : max(-view_pos.z, 0.05)) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	far_fade = ortho ? 0.0 : smoothstep(fade_near, fade_far, -view_pos.z);
	float scale = max(1.0, VIEWPORT_SIZE.y / 1080.0);
	float w = min(max(width_px * mix(1.0, 0.7, far_fade), 1.0 / scale) * scale * pixel, max_world);
	vec2 across = view_n.xy;
	float len = length(across);
	if (len > 0.0001) view_pos.xy += across / len * w;
	view_pos.z -= w * 2.5 + 0.002;
	POSITION = PROJECTION_MATRIX * view_pos;
}
void fragment() {
	// only the dark ink fades (a marked target's colour stays readable far away)
	float dark = 1.0 - smoothstep(0.22, 0.4, dot(ink.rgb, vec3(0.299, 0.587, 0.114)));
	ALBEDO = mix(ink.rgb, ink_far.rgb, far_fade * dark);
}
