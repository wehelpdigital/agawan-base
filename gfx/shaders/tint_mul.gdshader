// Colours everything under it, as overcast light does.
shader_type canvas_item;
render_mode blend_mul;
uniform vec4 tint = vec4(1.0);

void fragment() {
	COLOR = tint;
}
