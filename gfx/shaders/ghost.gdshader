// A see-through version of the toon look, for players who are hidden or ghosting.
shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_opaque;

uniform vec4 tint = vec4(1.0);
uniform float alpha = 0.45;
varying vec3 world_n;

void vertex() {
	world_n = mat3(MODEL_MATRIX) * NORMAL;
}

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = COLOR.rgb * tint.rgb + rim * 0.25;
	ALPHA = alpha * (0.65 + rim * 0.35);
}
