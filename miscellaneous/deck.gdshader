shader_type spatial;

uniform sampler2D albedo_tex;
uniform float threshold : hint_range(0.0, 1.0) = 0.8;
uniform vec3 top_dir = vec3(0.0, 1.0, 0.0);
uniform float stripe_frequency = 600.0; // More lines = thinner cards
uniform vec3 stripe_color_1 = vec3(0.85, 0.85, 0.85); // Light card edge
uniform vec3 stripe_color_2 = vec3(0.15, 0.15, 0.15); // Darker shadow between

void fragment() {
    float up_facing = dot(NORMAL, top_dir);

    if (up_facing >= threshold) {
        // Top: card texture
        vec4 tex_color = texture(albedo_tex, UV);
        ALBEDO = tex_color.rgb;
    }
    else if (abs(up_facing) <= 0.2) {
        // Sides: simulate stacked cards
        float stripes = floor(VERTEX.y * stripe_frequency);
        bool even = int(stripes) % 2 == 0;
        ALBEDO = even ? stripe_color_1 : stripe_color_2;
    }
    else {
        // Bottom or angled faces
        ALBEDO = vec3(0.1); // Even darker base
    }
}
