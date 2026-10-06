// Goes on the altar base sprite. Detects the blue rune pixels and fades them
// toward the stone color when dormant, then pulses them bright when active.
shader_type canvas_item;

uniform float activation : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rune_glow : source_color = vec4(0.5, 0.8, 1.0, 1.0);
// Dormant look: how much color the runes lose (1 = fully grey) and how dark they get.
uniform float dormant_desaturation : hint_range(0.0, 1.0) = 0.6;
uniform float dormant_brightness : hint_range(0.0, 1.5) = 0.85;
uniform float active_brightness = 1.6;
uniform float pulse_speed = 2.0;
// Raise if non-rune pixels get caught, lower if runes are missed.
uniform float blue_threshold = 0.12;

// Keeps the node's modulate (e.g. the construct ghost tint) working.
varying vec4 node_modulate;

void vertex() {
	node_modulate = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float blueness = tex.b - max(tex.r, tex.g);
	float is_rune = step(blue_threshold, blueness);

	float grey = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 dormant_col = mix(tex.rgb, vec3(grey), dormant_desaturation) * dormant_brightness;

	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	vec3 active_col = tex.rgb * active_brightness * pulse + rune_glow.rgb * 0.2 * pulse;

	vec3 rune_col = mix(dormant_col, active_col, activation);
	COLOR = vec4(mix(tex.rgb, rune_col, is_rune), tex.a) * node_modulate;
}
