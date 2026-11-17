shader_type canvas_item;

uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.32;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	if (color.a < alpha_cutoff) {
		discard;
	}
	COLOR = color;
}
