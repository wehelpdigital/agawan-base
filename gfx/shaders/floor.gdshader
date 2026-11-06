// The ground of a world map: its soft colours from the vertices, with the look of the place drawn over them by maths, so
// a whole field of cobbles costs one quad's worth of triangles per half tile. `style` says which.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform float style = 0.0;
varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// A rounded box's distance: under zero inside.
float box(vec2 p, vec2 half_size, float round_by) {
	vec2 q = abs(p) - half_size + vec2(round_by);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - round_by;
}

void fragment() {
	vec3 col = COLOR.rgb;
	vec2 p = world.xz;
	float s = style + 0.5;
	if (s >= 1.0 && s < 2.0) { // Cobbles.
		vec2 g = p * vec2(1.3, 1.7);
		g.x += mod(floor(g.y), 2.0) * 0.5;
		vec2 f = fract(g) - 0.5;
		float d = box(f, vec2(0.44, 0.42), 0.2);
		col *= 1.0 - 0.28 * smoothstep(-0.05, 0.02, d);
		col *= 0.94 + 0.12 * hash(floor(g));
	} else if (s >= 2.0 && s < 3.0) { // Sand, in ripples.
		float ripple = sin(p.y * 2.6 + sin(p.x * 0.55) * 1.9 + sin(p.x * 1.7) * 0.4);
		col *= 1.0 + 0.055 * ripple;
		col *= 0.97 + 0.05 * hash(floor(p * 9.0));
	} else if (s >= 3.0 && s < 4.0) { // Asphalt, with a zebra crossing now and then.
		col *= 0.93 + 0.13 * hash(floor(p * 7.0));
		float across = mod(p.y, 18.0);
		if (across > 6.0 && across < 11.0) {
			float stripes = step(0.5, fract(p.x * 0.5));
			col = mix(col, vec3(0.93, 0.93, 0.88), stripes * 0.75);
		}
	} else if (s >= 4.0 && s < 5.0) { // Marble: big slabs in two tones, with thin joints.
		vec2 g = p / 3.0;
		vec2 f = fract(g) - 0.5;
		float d = box(f, vec2(0.485), 0.02);
		col *= mix(0.97, 1.03, mod(floor(g.x) + floor(g.y), 2.0));
		col *= 1.0 - 0.25 * smoothstep(-0.012, 0.004, d);
		float vein = abs(sin(p.x * 0.9 + sin(p.y * 1.3) * 1.6 + p.y * 0.4));
		col *= 1.0 - 0.05 * (1.0 - smoothstep(0.0, 0.05, vein));
	} else if (s >= 5.0 && s < 6.0) { // A seaside promenade: bold waves in pale and dark.
		float wave = sin(p.x * 1.15 + sin(p.y * 1.25) * 1.35);
		col = mix(col, col * vec3(0.3, 0.3, 0.36), smoothstep(-0.05, 0.05, wave) * 0.82);
	} else if (s >= 6.0 && s < 7.0) { // Wooden planks.
		vec2 g = p * vec2(0.28, 1.0);
		g.x += hash(vec2(floor(g.y), 1.0)) * 3.0;
		vec2 f = fract(g);
		float gap = smoothstep(0.93, 0.97, f.y) + smoothstep(0.985, 0.995, f.x);
		col *= 0.96 + 0.1 * hash(floor(g));
		col *= 1.0 - 0.4 * clamp(gap, 0.0, 1.0);
		col *= 1.0 + 0.03 * sin(p.x * 9.0 + sin(p.y * 7.0));
	} else if (s >= 7.0 && s < 8.0) { // Rows of tulips: stripes of colour across the field.
		float row = floor(p.y / 3.0);
		vec3 flower = vec3(1.0, 0.36, 0.48);
		float pick = mod(row, 4.0);
		if (pick > 2.5) { flower = vec3(1.0, 0.85, 0.3); }
		else if (pick > 1.5) { flower = vec3(1.0, 0.6, 0.22); }
		else if (pick > 0.5) { flower = vec3(1.0, 0.55, 0.78); }
		vec2 f = fract(p * vec2(1.6, 1.4)) - 0.5;
		float dot_shape = 1.0 - smoothstep(0.24, 0.34, length(f));
		float band = smoothstep(0.1, 0.25, fract(p.y / 3.0)) * (1.0 - smoothstep(0.72, 0.85, fract(p.y / 3.0)));
		col = mix(col, flower, band * (0.42 + 0.5 * dot_shape));
	} else if (s >= 8.0 && s < 9.0) { // Snow: soft drifts, and the odd sparkle.
		float drift = sin(p.x * 0.5 + sin(p.y * 0.7) * 1.3) * sin(p.y * 0.45 + 1.0);
		col *= 1.0 + 0.03 * drift;
		col += vec3(0.5) * step(0.992, hash(floor(p * 14.0)));
	} else if (s >= 9.0 && s < 10.0) { // Zellige: star tiles.
		vec2 g = p / 2.0;
		vec2 f = fract(g) - 0.5;
		vec2 r = abs(mat2(vec2(0.707, 0.707), vec2(-0.707, 0.707)) * f);
		float star = max(max(abs(f.x), abs(f.y)), max(r.x, r.y));
		float line = 1.0 - smoothstep(0.0, 0.03, abs(star - 0.3));
		col = mix(col, vec3(0.1, 0.5, 0.56), (1.0 - smoothstep(0.26, 0.28, star)) * 0.55);
		col = mix(col, vec3(0.98, 0.93, 0.8), line * 0.85);
	} else if (s >= 10.0 && s < 11.0) { // Bricks.
		vec2 g = p * vec2(0.8, 1.6);
		g.x += mod(floor(g.y), 2.0) * 0.5;
		vec2 f = fract(g) - 0.5;
		float d = box(f, vec2(0.46, 0.42), 0.05);
		col *= 0.94 + 0.13 * hash(floor(g));
		col *= 1.0 - 0.28 * smoothstep(-0.03, 0.01, d);
	} else if (s >= 11.0 && s < 12.0) { // Big old flagstones.
		vec2 g = p * 0.55;
		g.x += mod(floor(g.y), 2.0) * 0.5 + sin(floor(g.y) * 3.7) * 0.2;
		vec2 f = fract(g) - 0.5;
		float d = box(f, vec2(0.46), 0.1);
		col *= 0.93 + 0.14 * hash(floor(g));
		col *= 1.0 - 0.3 * smoothstep(-0.03, 0.015, d);
	} else if (s >= 12.0 && s < 13.0) { // Raked gravel.
		float rake = sin(p.y * 7.0 + sin(p.x * 0.7) * 2.2);
		col *= 1.0 + 0.05 * rake;
		col *= 0.95 + 0.1 * hash(floor(p * 11.0));
	} else if (s >= 13.0 && s < 14.0) { // Dry ground, cracked here and there.
		vec2 g = p * 0.9 + vec2(sin(p.y * 1.3), sin(p.x * 1.1)) * 0.22;
		vec2 f = abs(fract(g) - 0.5);
		float crack = smoothstep(0.47, 0.495, max(f.x, f.y)) * step(0.45, hash(floor(g)));
		col *= 1.0 - 0.2 * crack;
		col *= 0.96 + 0.08 * hash(floor(p * 5.0));
	} else if (s >= 14.0 && s < 15.0) { // Rough grass.
		col *= 1.0 + 0.05 * sin(p.x * 3.1 + sin(p.y * 2.1) * 2.0) * sin(p.y * 2.7);
	}
	ALBEDO = col;
}
