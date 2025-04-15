shader_type spatial;
render_mode unshaded;

uniform sampler2D refl_tx;

void vertex() {
}

void fragment() {
	ALBEDO = texture(refl_tx, vec2(UV.x, 1.0-UV.y)).rgb;
}