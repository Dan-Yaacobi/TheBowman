shader_type canvas_item;
render_mode unshaded;

uniform vec4 inner_color : source_color = vec4(0.7, 0.9, 1.0, 1.0); // core
uniform vec4 outer_color : source_color = vec4(0.2, 0.4, 1.0, 0.0); // glow/edge (alpha can be low)
uniform float core_width : hint_range(0.0, 0.5) = 0.2;              // how thick the bright center is

uniform float pulse_strength : hint_range(0.0, 1.0) = 0.7;
uniform float speed : hint_range(0.0, 20.0) = 8.0;

void fragment() {
    // distance from center of the line (0.5 = middle of width)
    float dist = abs(UV.y - 0.5);

    // 1 at center, 0 at edges
    float core_mask = 1.0 - smoothstep(core_width, 0.5, dist);

    // blend between outer and inner based on core_mask
    vec4 col = mix(outer_color, inner_color, core_mask);

    // pulse brightness
    float t = (sin(TIME * speed) * 0.5 + 0.5); // 0..1
    col.rgb *= 1.0 + t * pulse_strength;

    COLOR = col;
}
