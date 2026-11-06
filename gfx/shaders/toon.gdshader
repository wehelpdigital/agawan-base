// Everything solid in the game: vertex colours lit by a fixed sun in two hard bands, with cool shadows
// and a thin rim light. Unshaded, so it costs the same on every device and needs no light nodes.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec3 sun_dir = vec3(-0.45, 0.82, 0.38);
uniform vec4 tint = vec4(1.0);
uniform float flash = 0.0;
uniform float soft = 0.0; // 1: gentle light and a glossy shine, for avatars, like a vinyl toy.
varying vec3 world_n;

void vertex() {
	world_n = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	vec3 n = normalize(world_n);
	vec3 sun = normalize(sun_dir);
	float ndl = dot(n, sun);
	float hard = smoothstep(-0.12, -0.02, ndl) * 0.55 + smoothstep(0.42, 0.5, ndl) * 0.45;
	float gentle = smoothstep(-0.8, 0.7, ndl);
	float band = mix(hard, gentle, soft);
	vec3 col = COLOR.rgb * tint.rgb;
	vec3 shade = col * mix(vec3(0.5, 0.46, 0.68), vec3(0.74, 0.68, 0.84), soft);
	vec3 lit = mix(shade, col, band);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - facing, 3.0);
	vec3 sun_view = normalize((VIEW_MATRIX * vec4(sun, 0.0)).xyz);
	float shine = pow(max(dot(NORMAL, normalize(sun_view + VIEW)), 0.0), 48.0) * soft * 0.17;
	vec3 surface = lit + rim * 0.1 * band * col * (1.0 - soft) + vec3(shine);
	// Avatars' outline: a dark edge where a round surface turns away, smooth at any distance. Vertex alpha
	// switches it off for paint (cheeks, spots, mouths).
	float line = soft * COLOR.a * smoothstep(0.7, 0.8, 1.0 - facing);
	surface = mix(surface, vec3(0.039, 0.078, 0.149), line);
	ALBEDO = mix(surface, vec3(1.0), flash);
}
