// A flag on a pole: a picture on a sheet that ripples outward from the pole, more the further it gets.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D picture : source_color, filter_linear_mipmap;
uniform float flutter = 1.0;
varying float shade;

void vertex() {
	float along = 1.0 - UV.x;
	float wave = sin(along * 7.0 - TIME * 7.0 + UV.y * 1.5);
	VERTEX.z += wave * 0.06 * along * flutter;
	VERTEX.y -= along * along * 0.05;
	shade = 0.86 + 0.14 * cos(along * 7.0 - TIME * 7.0 + UV.y * 1.5);
}

void fragment() {
	vec4 tex = texture(picture, UV);
	ALBEDO = tex.rgb * shade;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = tex.a;
}
