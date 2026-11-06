// The little planet the menus stand on: the world map on a ball, lit softly from the sun, with bright air round its edge.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform sampler2D picture : filter_linear_mipmap, repeat_enable;
varying vec3 world_n;

void vertex() {
	world_n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 col = texture(picture, UV).rgb;
	float light = dot(normalize(world_n), normalize(vec3(-0.35, 0.86, 0.38)));
	col *= 0.82 + 0.24 * smoothstep(-0.2, 0.9, light);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	col = mix(col, vec3(0.78, 0.95, 1.0), pow(1.0 - facing, 3.0) * 0.8);
	ALBEDO = col;
}
