shader_type canvas_item;

uniform float rope_density : hint_range(2.0, 40.0) = 16.0;
uniform float twist_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 dark_color : source_color = vec4(0.25, 0.18, 0.12, 1.0);
uniform vec4 light_color : source_color = vec4(0.45, 0.32, 0.22, 1.0);

void fragment() {
	// UV.x = along the rope
	// UV.y = across thickness
	vec2 uv = UV;

	// Diagonal twist illusion
	float twist = uv.x * rope_density + uv.y * twist_strength * rope_density;

	// Stripe pattern
	float stripe = step(0.5, fract(twist));

	// Color mix
	vec4 rope_color = mix(dark_color, light_color, stripe);

	COLOR = rope_color * COLOR;
}
