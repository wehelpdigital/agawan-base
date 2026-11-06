// Rain, snow, sand and petals, for very little: each drop is one quad with a place in a big box. The box follows the camera and
// wraps round, so nothing here ever has to be touched from script but `center` and `offset`.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, depth_test_disabled;

uniform sampler2D atlas : filter_linear_mipmap;
uniform vec3 center = vec3(0.0);
uniform vec3 offset = vec3(0.0); // How far everything has fallen and blown so far.
uniform vec3 box_size = vec3(46.0, 16.0, 40.0);
uniform vec2 quad_size = vec2(0.1, 0.9);
uniform vec3 stretch_dir = vec3(0.0, 1.0, 0.0);
uniform float cell = 0.0;
uniform vec4 tint = vec4(1.0);
uniform float stretched = 0.0; // 1: long streaks along stretch_dir. 0: flat towards the camera.
varying vec2 cell_uv;

void vertex() {
	vec3 seed = MODEL_MATRIX[3].xyz; // 0..1 in each direction, chosen when the box was filled.
	vec3 place = mod(seed * box_size + offset - center + box_size * 0.5, box_size) - box_size * 0.5 + center;
	place.y = mod(seed.y * box_size.y + offset.y, box_size.y);
	vec4 view_place = VIEW_MATRIX * vec4(place, 1.0);
	vec2 q = VERTEX.xy;
	if (stretched > 0.5) {
		vec3 along = normalize((VIEW_MATRIX * vec4(stretch_dir, 0.0)).xyz);
		vec3 across = normalize(cross(along, vec3(0.0, 0.0, 1.0)));
		view_place.xyz += along * q.y * quad_size.y + across * q.x * quad_size.x;
	} else {
		float a = seed.x * 40.0 + TIME * (seed.y - 0.5) * 2.0;
		float c = cos(a);
		float s = sin(a);
		vec2 r = vec2(q.x * c - q.y * s, q.x * s + q.y * c);
		view_place.xy += r * quad_size;
	}
	POSITION = PROJECTION_MATRIX * view_place;
	float grid = 6.0;
	vec2 at = vec2(mod(cell, grid), floor(cell / grid));
	cell_uv = (at + UV) / grid;
}

void fragment() {
	vec4 tex = texture(atlas, cell_uv);
	ALBEDO = tint.rgb;
	ALPHA = tex.a * tint.a;
}
