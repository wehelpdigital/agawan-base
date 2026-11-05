// One draw call for every spark, star and puff on screen: camera-facing quads from a multimesh, each
// picking its shape from a 4x4 atlas. INSTANCE_CUSTOM: x = atlas cell, y = size, z = spin, w = additive.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, depth_test_disabled;

uniform sampler2D atlas : filter_linear_mipmap;
varying vec2 cell_uv;

void vertex() {
	float cell = INSTANCE_CUSTOM.x;
	float size = INSTANCE_CUSTOM.y;
	float spin = INSTANCE_CUSTOM.z;
	vec4 center = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float c = cos(spin);
	float s = sin(spin);
	vec2 q = VERTEX.xy * size;
	center.xy += vec2(q.x * c - q.y * s, q.x * s + q.y * c);
	POSITION = PROJECTION_MATRIX * center;
	vec2 grid = vec2(mod(cell, 4.0), floor(cell / 4.0));
	cell_uv = (grid + vec2(UV.x, UV.y)) / 4.0;
}

void fragment() {
	vec4 tex = texture(atlas, cell_uv);
	ALBEDO = tex.rgb * COLOR.rgb;
	ALPHA = tex.a * COLOR.a;
}
