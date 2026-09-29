// Inverted-hull ink outline with constant on-screen width.
// Extrudes along welded (smoothed) normals stored in TANGENT, so hard-edged
// parts do not crack at corners, and in clip space, so stretched parts keep
// an even line. Only attached on the high graphics preset.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;
uniform vec4 ink : source_color = vec4(0.10, 0.11, 0.16, 1.0);
uniform float width_px = 2.4;
uniform float max_world = 0.02;
void vertex() {
	vec3 smooth_n = TANGENT.xyz;
	if (dot(smooth_n, smooth_n) < 0.0001) smooth_n = NORMAL;
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_n = normalize(MODELVIEW_NORMAL_MATRIX * smooth_n);
	vec4 clip = PROJECTION_MATRIX * view_pos;
	vec2 dir = (PROJECTION_MATRIX * vec4(view_n, 0.0)).xy;
	float len = length(dir);
	if (len > 0.00001) {
		// Pixel-constant offset, capped in world units so distant heroes do
		// not turn into ink blobs.
		vec2 px = dir / len * width_px * 2.0 / VIEWPORT_SIZE;
		float cap = max_world * PROJECTION_MATRIX[0][0] / max(-view_pos.z, 0.001);
		clip.xy += px * min(clip.w, cap * clip.w / max(length(px), 0.00001));
	}
	POSITION = clip;
}
void fragment() {
	ALBEDO = ink.rgb;
}
