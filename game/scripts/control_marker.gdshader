shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;
uniform sampler2D glyph : source_color, filter_linear_mipmap;
uniform vec4 base_color : source_color = vec4(0.96,0.87,0.63,1.0);
uniform vec4 fill_color : source_color = vec4(0.41,0.74,1.0,1.0);
uniform float progress : hint_range(0.0,1.0) = 0.0;
void vertex() {
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
    vec4 mask = texture(glyph,UV);
    // Fill the letter and arrow separately, avoiding the transparent spacing.
    float pixel_y = UV.y*384.0;
    float local_y = pixel_y<285.0 ? (pixel_y-40.0)/219.0 : (pixel_y-303.0)/52.0;
    float filled = step(1.0-progress,clamp(local_y,0.0,1.0));
    ALBEDO = mix(vec3(0.015),mix(base_color.rgb,fill_color.rgb,filled),mask.r);
    ALPHA = mask.a;
}
