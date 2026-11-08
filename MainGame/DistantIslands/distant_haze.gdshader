shader_type canvas_item;

// Fades a sprite toward the sky color so it reads as far away.
uniform vec4 haze_color : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform float haze_amount : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// COLOR already holds texture * modulate here.
	COLOR.rgb = mix(COLOR.rgb, haze_color.rgb, haze_amount);
}
