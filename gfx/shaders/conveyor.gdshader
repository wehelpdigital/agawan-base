// Strips of moving arrows: conveyor belts and dash floors. Their direction is stored in the vertex colour.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec4 belt = vec4(0.25, 0.25, 0.32, 1.0);
uniform vec4 mark = vec4(1.0, 0.82, 0.25, 1.0);
uniform float speed = 3.3;
uniform float tile = 2.0;
varying vec3 world;
varying vec2 dir;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	dir = COLOR.rg * 2.0 - 1.0;
}

void fragment() {
	vec2 side = vec2(-dir.y, dir.x);
	float along = dot(world.xz, dir);
	float across = abs(fract(dot(world.xz, side) / tile) - 0.5);
	float wave = fract((along - across * 1.5) / tile * 1.5 - TIME * speed * 0.42);
	float arrow = smoothstep(0.5, 0.46, wave) * smoothstep(0.0, 0.04, wave);
	ALBEDO = mix(belt.rgb, mark.rgb, arrow);
}
