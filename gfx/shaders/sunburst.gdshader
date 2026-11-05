// The menu background: slowly turning rays over a gradient, with a soft glow in the middle.
shader_type canvas_item;

uniform vec4 top_color = vec4(0.45, 0.25, 0.9, 1.0);
uniform vec4 low_color = vec4(0.16, 0.08, 0.42, 1.0);
uniform vec4 glow_color = vec4(1.0, 0.6, 0.9, 1.0);
uniform vec2 center = vec2(0.5, 0.42);
uniform float aspect = 1.78;
uniform float rays = 16.0;

void fragment() {
	vec2 p = UV - center;
	p.x *= aspect;
	float angle = atan(p.y, p.x) + TIME * 0.05;
	float ray = step(0.0, sin(angle * rays));
	vec3 base = mix(top_color.rgb, low_color.rgb, UV.y);
	vec3 col = mix(base, base * 1.2 + vec3(0.02, 0.01, 0.05), ray);
	float d = length(p);
	col += glow_color.rgb * (1.0 - smoothstep(0.0, 0.75, d)) * 0.24;
	col *= 1.0 - smoothstep(0.55, 1.25, d) * 0.3;
	COLOR = vec4(col, 1.0);
}
