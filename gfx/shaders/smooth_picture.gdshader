// Draws a picture smaller than it really is without it going jagged, by averaging what falls under each screen pixel. It does
// the job of stored smaller copies of the picture, which would add a quarter again to the download.
shader_type canvas_item;

varying vec4 tint;

void vertex() {
	tint = COLOR;  // By the fragment stage, COLOR has the picture mixed into it already.
}

void fragment() {
	vec2 d = fwidth(UV) * 0.3;
	vec4 sum = texture(TEXTURE, UV + vec2(-d.x, -d.y)) + texture(TEXTURE, UV + vec2(d.x, -d.y))
		+ texture(TEXTURE, UV + vec2(-d.x, d.y)) + texture(TEXTURE, UV + vec2(d.x, d.y));
	COLOR = sum * 0.25 * tint;
}
