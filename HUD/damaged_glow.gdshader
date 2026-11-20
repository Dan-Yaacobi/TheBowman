shader_type canvas_item;

// Red glow around the screen edges when the player is hit. Fade it with the node's modulate alpha.
uniform vec4 glow_color : source_color = vec4(0.85, 0.08, 0.06, 1.0);
// Distance from the centre (0 = centre, 1 = corner) where the glow starts / reaches full strength.
uniform float inner_radius : hint_range(0.0, 1.0) = 0.35;
uniform float outer_radius : hint_range(0.0, 1.5) = 0.95;
// Faint tint kept in the middle of the screen.
uniform float center_strength : hint_range(0.0, 1.0) = 0.12;

void fragment() {
	float dist = length((UV - vec2(0.5)) * 2.0) / sqrt(2.0);
	float edge = smoothstep(inner_radius, outer_radius, dist);
	float strength = mix(center_strength, 1.0, edge);
	COLOR = vec4(glow_color.rgb, glow_color.a * strength * COLOR.a);
}
