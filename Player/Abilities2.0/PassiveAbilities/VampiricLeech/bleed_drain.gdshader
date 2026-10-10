shader_type canvas_item;

// 0 = invisible, 1 = full. Tweened by BleedDrainLine.
uniform float strength : hint_range(0.0, 1.0) = 1.0;

// Same palette as blood.gdshader.
uniform vec4 dark_blood : source_color = vec4(0.16, 0.0, 0.03, 1.0);
uniform vec4 blood_color : source_color = vec4(0.62, 0.02, 0.07, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.28, 0.25, 1.0);

// Thickness of the stream as a fraction of the line's width.
uniform float thickness : hint_range(0.05, 0.5) = 0.18;
// Sideways wiggle of the stream inside the line's width.
uniform float wave_amount : hint_range(0.0, 0.3) = 0.15;
uniform float wave_count : hint_range(0.0, 20.0) = 4.0;
// How fast blood flows from the enemy (start of the line) to the player (end).
uniform float flow_speed : hint_range(0.0, 10.0) = 3.0;
// Bright droplets travelling along the stream.
uniform float droplet_count : hint_range(1.0, 30.0) = 8.0;

void fragment() {
	// UV.x runs 0 -> 1 from enemy to player, UV.y 0 -> 1 across the width.
	float wave = sin(UV.x * wave_count * TAU - TIME * flow_speed * 4.0) * wave_amount;
	// Pinch the stream at both ends so it connects to the enemy and player as points.
	float pinch = smoothstep(0.0, 0.15, UV.x) * smoothstep(1.0, 0.85, UV.x);
	float dist = abs(UV.y - 0.5 - wave * pinch);
	float width = thickness * mix(0.4, 1.0, pinch);

	vec3 col = blood_color.rgb;
	float alpha = step(dist, width);

	// Dark edge on the stream, so it reads against bright skies.
	col = mix(dark_blood.rgb, col, step(dist, width * 0.6));

	// Droplets flowing toward the player.
	float drop = fract(UV.x * droplet_count - TIME * flow_speed);
	float is_drop = step(drop, 0.25) * step(dist, width * 1.4);
	col = mix(col, highlight_color.rgb, is_drop);
	alpha = max(alpha, is_drop);

	COLOR = vec4(col, alpha * strength);
}
