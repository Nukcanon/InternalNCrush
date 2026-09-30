// Cartoon surface: two-tone cel ramp, soft rim light, painted highlight and a
// sky/ground ambient gradient. One pass, vertex colours only, no texture
// fetches, so a whole character costs a few cheap draws on integrated GPUs.
shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float vertex_color = 1.0;
uniform vec3 light_direction = vec3(0.45, 0.8, 0.35);
uniform float exposure = 0.86;
uniform float shadow_strength = 0.48; // 1.4.2: slightly deeper shade
uniform float rim_strength = 0.22;
uniform vec3 shadow_tint : source_color = vec3(0.52, 0.56, 0.78);
uniform vec3 sky_fill : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 ground_fill : source_color = vec3(0.78, 0.72, 0.66);
uniform float gloss = 0.0;
varying vec3 paint;
varying vec3 world_normal;
void vertex() {
	paint = mix(tint.rgb, COLOR.rgb * tint.rgb, vertex_color);
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 n = normalize(world_normal);
	float lit = dot(n, normalize(light_direction));
	float band = smoothstep(-0.04, 0.10, lit);
	// Surfaces facing down receive warm bounce, surfaces facing up the sky.
	vec3 fill = mix(ground_fill, sky_fill, n.y * 0.5 + 0.5);
	vec3 shadowed = paint * mix(vec3(1.0), shadow_tint, shadow_strength) * (1.0 - shadow_strength * 0.6);
	vec3 shade = mix(shadowed, paint, band) * fill;
	vec3 view = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float rim = pow(1.0 - clamp(dot(n, view), 0.0, 1.0), 3.0) * rim_strength * (0.4 + 0.6 * band);
	float spot = gloss * smoothstep(0.93, 0.97, dot(reflect(-normalize(light_direction), n), view));
	vec3 color = (shade + rim * mix(paint, vec3(1.0), 0.5) + spot) * exposure;
	if (OUTPUT_IS_SRGB) color = pow(max(color, vec3(0.0)), vec3(0.454545));
	ALBEDO = vec3(0.0);
	EMISSION = color;
}
