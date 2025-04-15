shader_type spatial;
render_mode unshaded;

uniform sampler2D refl_tx;

void fragment() {
	vec2 flipped_uv = vec2(1.0 - UV.x, 1.0 - UV.y); // Flip both horizontally and vertically
	ALBEDO = texture(refl_tx, flipped_uv).rgb;
}
