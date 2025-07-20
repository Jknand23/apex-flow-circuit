shader_type spatial;

uniform float cel_levels : hint_range(2.0, 10.0) = 4.0;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color;

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb * base_color.rgb;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float cel_light = floor(NdotL * cel_levels) / cel_levels;
    cel_light = max(cel_light, 0.1);

    DIFFUSE_LIGHT += cel_light * LIGHT_COLOR * ATTENUATION;
}