shader_type spatial;
render_mode unshaded;
void fragment(){
 vec2 p=UV-vec2(.5);
 float r=length(p)*2.0;
 float rings=0.88+0.12*sin(r*210.0);
 float glow=clamp(1.0-r*.55,.3,1.0);
 ALBEDO=vec3(0.85,0.32,0.065)*glow*rings;
 EMISSION=vec3(1.0,.42,.08)*glow*rings*2.0;
}
