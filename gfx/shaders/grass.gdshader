// Bushes you can walk into. They're a little see-through at all times, so they read as leaves and not as a wall, and
// fade right back round anyone you're allowed to see inside them. Enemies hiding in there aren't drawn at all.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_always, blend_mix;

uniform vec3 reveals[6];
varying vec3 world_n;
varying vec3 world_p;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sway = sin(TIME * 1.7 + w.x * 0.9 + w.z * 0.7) * 0.05 * VERTEX.y * VERTEX.y;
	VERTEX.x += sway;
	VERTEX.z += sway * 0.5;
	world_p = w;
	world_n = mat3(MODEL_MATRIX) * NORMAL;
}

void fragment() {
	float light = smoothstep(-0.4, 0.8, dot(normalize(world_n), normalize(vec3(-0.45, 0.82, 0.38))));
	vec3 col = COLOR.rgb * mix(0.74, 1.05, light);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	ALBEDO = mix(col, COLOR.rgb * 0.5, smoothstep(0.62, 0.92, 1.0 - facing));
	float near = 0.0;
	for (int i = 0; i < 6; i++) {
		near = max(near, 1.0 - smoothstep(1.2, 2.9, distance(world_p.xz, reveals[i].xz)));
	}
	ALPHA = mix(0.74, 0.14, near);
}
