// Everything solid in the game: vertex colours lit by a fixed sun in two hard bands, with cool shadows
// and a thin rim light. Unshaded, so it costs the same on every device and needs no light nodes.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec3 sun_dir = vec3(-0.45, 0.82, 0.38);
uniform vec4 tint = vec4(1.0);
uniform float flash = 0.0;
varying vec3 world_n;

void vertex() {
	world_n = mat3(MODEL_MATRIX) * NORMAL;
}

void fragment() {
	vec3 n = normalize(world_n);
	float ndl = dot(n, normalize(sun_dir));
	float band = smoothstep(-0.12, -0.02, ndl) * 0.55 + smoothstep(0.42, 0.5, ndl) * 0.45;
	vec3 col = COLOR.rgb * tint.rgb;
	vec3 shade = col * vec3(0.5, 0.46, 0.68);
	vec3 lit = mix(shade, col, band);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(lit + rim * 0.1 * band * col, vec3(1.0), flash);
}
