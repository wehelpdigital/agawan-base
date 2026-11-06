// Fog, dark, sand in the air: a sheet over the world with clear round holes where you can see. The holes are in screen space,
// with the middle and size of each in `holes` (x, y as 0..1 of the screen, z the radius as a share of its height).
shader_type canvas_item;

uniform vec4 veil = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec3 holes[8];
uniform float aspect = 1.78;
uniform float flash = 0.0;

void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y);
	float clear = 0.0;
	for (int i = 0; i < 8; i++) {
		if (holes[i].z > 0.0) {
			float d = distance(p, vec2(holes[i].x * aspect, holes[i].y));
			clear = max(clear, 1.0 - smoothstep(holes[i].z * 0.5, holes[i].z, d));
		}
	}
	float drift = sin(p.x * 4.3 + TIME * 0.34) * sin(p.y * 6.1 - TIME * 0.27) + sin(p.x * 9.0 - TIME * 0.2 + p.y * 7.0) * 0.5;
	float a = veil.a * (1.0 - clear) * (0.84 + 0.1 * drift);
	vec3 col = mix(veil.rgb, vec3(1.0), flash);
	COLOR = vec4(col, max(a, flash * 0.75));
}
