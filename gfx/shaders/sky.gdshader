// The menu background: a sunny sky with slow puffy clouds, over rolling green hills, like the lid of a toy box.
shader_type canvas_item;

uniform float aspect = 1.78;

float blob(vec2 p, vec2 at, vec2 size) {
	vec2 d = (p - at) / size;
	return 1.0 - smoothstep(0.92, 1.0, dot(d, d));
}

// One cloud: a flat bottom with three puffs on it.
float cloud(vec2 p, vec2 at, float s) {
	float c = blob(p, at, vec2(0.17, 0.05) * s);
	c = max(c, blob(p, at + vec2(-0.08, -0.03) * s, vec2(0.07, 0.06) * s));
	c = max(c, blob(p, at + vec2(0.0, -0.055) * s, vec2(0.09, 0.08) * s));
	c = max(c, blob(p, at + vec2(0.085, -0.03) * s, vec2(0.065, 0.055) * s));
	return c;
}

float hill(float x, float base, float height, float wave, float phase) {
	return base - height * (0.5 + 0.5 * sin(x * wave + phase));
}

void fragment() {
	vec2 uv = UV;
	vec2 p = vec2(uv.x * aspect, uv.y);
	vec3 col = mix(vec3(0.27, 0.70, 1.0), vec3(0.76, 0.94, 1.0), smoothstep(0.0, 0.72, uv.y));
	// The sun, low and soft in one corner.
	float sun = length(p - vec2(aspect * 0.86, 0.13));
	col += vec3(1.0, 0.86, 0.45) * (1.0 - smoothstep(0.0, 0.5, sun)) * 0.34;
	col = mix(col, vec3(1.0, 0.95, 0.65), 1.0 - smoothstep(0.075, 0.085, sun));
	// Clouds drift across and come round again.
	float drift = TIME * 0.012;
	float wide = aspect + 0.6;
	for (int i = 0; i < 5; i++) {
		float n = float(i);
		float x = mod(n * 0.71 * wide + drift * (1.0 + n * 0.35), wide) - 0.3;
		float y = 0.1 + mod(n * 0.37, 0.48);
		float size = 0.8 + mod(n * 0.53, 0.8);
		float c = cloud(p, vec2(x, y), size);
		float under = cloud(p, vec2(x, y + 0.008 * size), size);
		col = mix(col, vec3(0.86, 0.94, 1.0), under);
		col = mix(col, vec3(1.0), c);
	}
	// Three layers of hills, and a line of light along the top of each.
	float x = uv.x * aspect;
	float far = hill(x, 0.8, 0.09, 3.1, 0.6);
	float mid = hill(x, 0.87, 0.08, 4.3, 2.2);
	float near = hill(x, 0.95, 0.07, 2.7, 4.4);
	col = mix(col, vec3(0.49, 0.83, 0.52), smoothstep(far, far + 0.002, uv.y));
	col = mix(col, vec3(0.35, 0.78, 0.36), smoothstep(mid, mid + 0.002, uv.y));
	col = mix(col, vec3(0.62, 0.90, 0.42), smoothstep(mid, mid + 0.002, uv.y) * (1.0 - smoothstep(mid + 0.004, mid + 0.012, uv.y)));
	col = mix(col, vec3(0.28, 0.70, 0.27), smoothstep(near, near + 0.002, uv.y));
	col = mix(col, vec3(0.55, 0.86, 0.36), smoothstep(near, near + 0.002, uv.y) * (1.0 - smoothstep(near + 0.004, near + 0.012, uv.y)));
	COLOR = vec4(col, 1.0);
}
