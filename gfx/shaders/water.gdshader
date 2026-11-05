// Water, lava, syrup and the void between platforms. Painted from world position, so tiles join up.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec4 base_color = vec4(0.2, 0.7, 0.9, 1.0);
uniform vec4 foam_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float speed = 0.5;
uniform float glow = 0.0;
varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world.x * 1.4 + TIME * 1.8) * cos(world.z * 1.1 + TIME * 1.3) * 0.05;
}

float ripple(vec2 p, float t) {
	return sin(p.x + sin(p.y * 0.7 + t) * 1.5 + t) * sin(p.y * 1.3 - t * 0.7 + sin(p.x * 0.5));
}

void fragment() {
	vec2 p = world.xz * 2.2;
	float r = ripple(p, TIME * speed * 2.0);
	float crest = smoothstep(0.55, 0.62, r);
	float deep = smoothstep(-0.6, 0.2, r);
	vec3 col = mix(base_color.rgb * 0.8, base_color.rgb, deep);
	col = mix(col, foam_color.rgb, crest * 0.55);
	ALBEDO = col + base_color.rgb * glow * (0.5 + 0.5 * sin(TIME * 2.0 + world.x));
}
