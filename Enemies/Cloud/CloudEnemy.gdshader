shader_type canvas_item;
render_mode unshaded;

// 0 = idle, 1 = fully charged
uniform float charge : hint_range(0.0, 1.0) = 0.0;

uniform vec4 base_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 charge_tint : source_color = vec4(0.6, 0.9, 1.5, 1.0);
uniform float pulse_speed : hint_range(0.0, 20.0) = 8.0;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    if (tex.a < 0.1) {
        discard; // keep pixel-art edges clean
    }

    // base cloud color
    vec4 col = tex * base_tint;

    // pulse factor (for charging glow)
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);

    // bottom of cloud (where lightning comes from)
    float bottom = smoothstep(0.3, 1.0, UV.y); // 0 near top, 1 near bottom

    // brighten + tint bottom as charge grows
    float core = bottom * charge * (0.4 + 0.6 * pulse);
    col.rgb = mix(col.rgb, charge_tint.rgb, core);

    // darken the top when charging (stormier)
    float top = 1.0 - bottom;
    col.rgb *= mix(1.0, 0.7, charge * top);

    // electric "veins" near bottom center
    float center = 1.0 - abs(UV.x - 0.5) * 2.0; // 1 in center, 0 at sides
    float mask = clamp(center * bottom, 0.0, 1.0) * charge;

    // noisy flickering pattern
	vec2 cell = vec2(floor(UV.x * 64.0), floor(UV.y * 64.0) + floor(TIME * 20.0));
    float n = hash(cell);
    float vein = step(0.95, n) * mask; // sparse bright spots

    col.rgb += vein * vec3(0.7, 0.9, 1.4);

    COLOR = col;
}
