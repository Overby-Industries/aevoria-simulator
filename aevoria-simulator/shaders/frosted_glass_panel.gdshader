shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.05);
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Blur the viewport behind the panel
    vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount);

    // Mix with a subtle white tint
    COLOR = mix(blurred, tint_color, tint_color.a);
}
