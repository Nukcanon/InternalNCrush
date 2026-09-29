// Cartoon hero surface: two-tone cel ramp, soft rim light and a painted
// highlight. One pass, vertex colours only, no texture fetches, so a whole
// character costs a few cheap draw calls on integrated GPUs and WebGL.
shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float vertex_color = 1.0;
uniform vec3 light_direction = vec3(0.45, 0.8, 0.35);
uniform float shadow_strength = 0.30;
uniform float rim_strength = 0.35;
uniform vec3 shadow_tint : source_color = vec3(0.55, 0.55, 0.80);
uniform float gloss = 0.0;
varying vec3 paint;
varying vec3 world_normal;
void vertex() {
	paint = mix(tint.rgb, COLOR.rgb * tint.rgb, vertex_color);
	if (OUTPUT_IS_SRGB) paint = pow(max(paint, vec3(0.0)), vec3(0.454545));
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 n = normalize(world_normal);
	float lit = dot(n, normalize(light_direction));
	// Hard cel edge softened slightly so it does not shimmer at a distance.
	float band = smoothstep(-0.05, 0.08, lit);
	vec3 shade = mix(paint * mix(vec3(1.0), shadow_tint, shadow_strength) * (1.0 - shadow_strength * 0.55), paint, band);
	vec3 view = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float rim = pow(1.0 - clamp(dot(n, view), 0.0, 1.0), 3.0) * rim_strength;
	float spot = gloss * smoothstep(0.92, 0.96, dot(reflect(-normalize(light_direction), n), view));
	ALBEDO = vec3(0.0);
	EMISSION = shade + rim * mix(paint, vec3(1.0), 0.6) + spot;
}
