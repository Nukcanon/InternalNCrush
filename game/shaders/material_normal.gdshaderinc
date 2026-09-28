global uniform bool material_detail_enabled;
uniform sampler2D detail_normal: hint_normal, filter_linear_mipmap, repeat_enable;
vec3 detail_surface_normal(vec3 normal, vec3 position, vec2 coords, vec3 sample_normal, float strength){
 vec3 dp1=dFdx(position), dp2=dFdy(position);
 vec2 duv1=dFdx(coords), duv2=dFdy(coords);
 vec3 p2=cross(dp2,normal), p1=cross(normal,dp1);
 vec3 t=p2*duv1.x+p1*duv2.x, b=p2*duv1.y+p1*duv2.y;
 float inv=inversesqrt(max(max(dot(t,t),dot(b,b)),.00000001));
 // Normal imports may use two-channel RGTC. Reconstruct Z instead of reading
 // an undefined/zero blue channel and accidentally pointing into the surface.
 vec2 xy=sample_normal.xy*2.-1.;
 vec3 bump=vec3(xy*strength,sqrt(max(.001,1.-dot(xy,xy))));
 return normalize(mat3(t*inv,b*inv,normal)*bump);
}
