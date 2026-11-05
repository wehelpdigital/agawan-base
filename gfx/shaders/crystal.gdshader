// The mystery crystal. Each face carries its place in the rainbow in COLOR.r and how bright it is in COLOR.g, and the
// colours drift with time, so it shimmers even standing still. Alpha 0 marks the dark outline around it.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

varying vec3 world_n;

void vertex() {
	world_n = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	if (COLOR.a < 0.5) {
		ALBEDO = vec3(0.14, 0.075, 0.37);
	} else {
		float hue = COLOR.r + TIME * 0.14;
		vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (hue + vec3(0.0, 0.33, 0.67)));
		vec3 col = mix(rainbow, vec3(1.0), 0.28) * COLOR.g;
		float glint = pow(max(sin(TIME * 2.2 + dot(normalize(world_n), vec3(3.0, 2.0, 3.0))), 0.0), 24.0);
		ALBEDO = col + vec3(glint * 0.7);
	}
}
