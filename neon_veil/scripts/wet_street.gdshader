shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D asphalt : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D puddles : filter_linear_mipmap, repeat_enable;
void fragment() {
 vec2 uv = UV * vec2(8.0, 32.0);
 float water = smoothstep(0.35, 0.54, texture(puddles, UV*vec2(3.0,9.0)).r);
 vec3 stone = texture(asphalt, uv).rgb;
 ALBEDO = stone * mix(0.95,0.62,water);
 METALLIC = mix(0.08,0.2,water);
 ROUGHNESS = mix(0.52,0.045,water);
 SPECULAR = 0.65;
 vec3 n = texture(normal_map,uv).rgb;
 vec2 ripples = vec2(sin(UV.x*550.0+TIME*1.2)*cos(UV.y*820.0+TIME*1.8),cos(UV.x*680.0-TIME)*sin(UV.y*490.0+TIME))*0.005;
 NORMAL_MAP = mix(n,vec3(vec2(0.5)+ripples,1.0),water*0.92);
 NORMAL_MAP_DEPTH = 0.55;
}
