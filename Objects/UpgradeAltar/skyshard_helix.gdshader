// Glowing spiral wisp rising from the pool and wrapping the crystal.
// Use TWO ColorRects with this shader: one behind the crystal (front_layer = false)
// and one in front (front_layer = true), so the spiral passes around it.
shader_type canvas_item;

uniform float activation : hint_range(0.0, 1.0) = 0.0;
uniform bool front_layer = true;

// Bright center of the line.
uniform vec4 core_color : source_color = vec4(0.95, 0.9, 1.0, 1.0);
// Glow color shifts from bottom (pool) to top (crystal).
uniform vec4 glow_bottom_color : source_color = vec4(0.45, 0.7, 1.0, 1.0);
uniform vec4 glow_top_color : source_color = vec4(0.75, 0.4, 1.0, 1.0);

uniform int strands = 2;
uniform float turns = 2.0;
uniform float speed = 2.0;
uniform float core_width = 0.04;
uniform float glow_width = 0.14;
uniform float glow_strength = 0.55;
uniform float glow_steps = 3.0;
uniform float base_radius = 0.08;
uniform float top_radius = 0.42;
uniform float back_brightness = 0.45;
// Bright pulses that travel up the spiral.
uniform float shimmer_speed = 4.0;
uniform float shimmer_density = 8.0;
// Set to the rect's size in pixels.
uniform vec2 pixel_res = vec2(24.0, 40.0);

void fragment() {
	vec2 uv = (floor(UV * pixel_res) + 0.5) / pixel_res;
	float y = 1.0 - uv.y;
	float taper = smoothstep(0.0, 0.12, y) * (1.0 - smoothstep(0.8, 1.0, y));
	float radius = mix(base_radius, top_radius, smoothstep(0.0, 0.45, y));
	vec3 glow_col = mix(glow_bottom_color.rgb, glow_top_color.rgb, y);
	float shimmer = 0.75 + 0.25 * sin(y * shimmer_density - TIME * shimmer_speed);

	float best_alpha = 0.0;
	vec3 best_col = vec3(0.0);
	for (int i = 0; i < strands; i++) {
		float phase = y * turns * TAU - TIME * speed + float(i) * TAU / float(strands);
		float x = 0.5 + sin(phase) * radius;
		float is_front = step(0.0, cos(phase));
		float layer_mask = front_layer ? is_front : 1.0 - is_front;
		float dist = abs(uv.x - x);

		float core = 1.0 - step(core_width, dist);
		float glow = clamp(1.0 - (dist - core_width) / (glow_width - core_width), 0.0, 1.0);
		glow = floor(glow * glow_steps) / glow_steps * glow_strength;

		float depth_dim = mix(back_brightness, 1.0, is_front);
		float a = max(core, glow) * layer_mask * depth_dim;
		vec3 col = mix(glow_col, core_color.rgb, core) * shimmer;
		if (a > best_alpha) {
			best_alpha = a;
			best_col = col;
		}
	}
	COLOR = vec4(best_col, best_alpha * taper * activation);
}
