shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : source_color;

void fragment() {
    vec2 flipped_uv = UV;
    ALBEDO = texture(screen_texture, flipped_uv).rgb;
}