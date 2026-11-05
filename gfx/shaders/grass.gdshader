// Tall grass: the same toon look as everything else, swaying in the wind (vertex alpha = sway amount).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

varying vec3 world_n;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sway = sin(TIME * 2.2 + w.x * 1.3 + w.z * 0.9) * 0.14 * COLOR.a;
	VERTEX.x += sway;
	VERTEX.z += sway * 0.5;
	world_n = mat3(MODEL_MATRIX) * NORMAL;
}

void fragment() {
	float band = smoothstep(-0.1, 0.0, dot(normalize(world_n), normalize(vec3(-0.45, 0.82, 0.38))));
	ALBEDO = mix(COLOR.rgb * vec3(0.55, 0.62, 0.72), COLOR.rgb, band * 0.5 + 0.5);
}
