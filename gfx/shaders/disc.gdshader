// Round flat markers on the ground: bases, capture rings, zones, player rings. One quad per marker.
// `style`: 0 soft disc with a rim, 1 thin ring, 2 progress ring (uses `fill`), 3 dashed spinning ring.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform vec4 color = vec4(1.0);
uniform float style = 0.0;
uniform float fill = 1.0;
uniform float inner_alpha = 0.25;
uniform float spin = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float a = 0.0;
	if (style < 0.5) {
		float rim = smoothstep(0.84, 0.88, d) * (1.0 - smoothstep(0.96, 1.0, d));
		float body = (1.0 - smoothstep(0.86, 0.9, d)) * inner_alpha;
		a = max(rim, body);
	} else if (style < 1.5) {
		a = smoothstep(0.78, 0.82, d) * (1.0 - smoothstep(0.96, 1.0, d));
	} else if (style < 2.5) {
		float angle = (atan(p.x, -p.y) + 3.14159265) / 6.2831853;
		a = smoothstep(0.7, 0.74, d) * (1.0 - smoothstep(0.96, 1.0, d)) * step(angle, fill);
	} else {
		float angle = atan(p.y, p.x) + TIME * spin;
		float dash = step(0.0, sin(angle * 8.0));
		a = smoothstep(0.82, 0.86, d) * (1.0 - smoothstep(0.96, 1.0, d)) * dash;
		a = max(a, (1.0 - smoothstep(0.84, 0.88, d)) * inner_alpha);
	}
	ALBEDO = color.rgb;
	ALPHA = a * color.a;
}
