shader_type canvas_item;

// Center of the swirl in UV space (portal interior)
uniform vec2 center = vec2(0.51, 0.5);
// Rotation speed; negative flips direction
uniform float speed : hint_range(-5.0, 5.0) = 1.2;
// Number of spiral arms
uniform float arms : hint_range(1.0, 6.0, 1.0) = 2.0;
// How tightly the arms wind
uniform float twist : hint_range(0.0, 40.0) = 14.0;
// Effective pixel-art resolution across the sprite's width (cells)
uniform float pixel_grid : hint_range(16.0, 512.0) = 80.0;
// Color banding for a pixel-art palette look
uniform int color_steps : hint_range(2, 8) = 4;

uniform vec4 deep_color : source_color = vec4(0.02, 0.12, 0.75, 1.0);
uniform vec4 mid_color : source_color = vec4(0.05, 0.35, 0.95, 1.0);
uniform vec4 bright_color : source_color = vec4(0.30, 0.85, 1.0, 1.0);

// Twinkling stars
uniform float star_density : hint_range(0.0, 0.1) = 0.025;
uniform float star_twinkle_speed : hint_range(0.0, 10.0) = 3.0;

// How much bluer than red a pixel must be to count as "portal"
uniform float blue_threshold : hint_range(0.0, 1.0) = 0.25;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 rotate(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

void fragment() {
	vec4 src = texture(TEXTURE, UV);

	// Mask: only the blue portal interior (stone is red-dominant, outline is dark, bg is grey/white)
	bool is_portal = (src.b - src.r) > blue_threshold && src.b > 0.35 && src.a > 0.5;

	if (!is_portal) {
		COLOR = src;
	} else {
		// Keep cells square regardless of texture aspect
		float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x; // width / height
		vec2 grid = vec2(pixel_grid, pixel_grid / aspect);
		vec2 cell = floor(UV * grid);
		vec2 snapped_uv = (cell + 0.5) / grid;

		vec2 d = (snapped_uv - center) * vec2(aspect, 1.0);
		float r = length(d);
		float a = atan(d.y, d.x);

		// Spiral pattern
		float s = sin(a * arms + r * twist - TIME * speed) * 0.5 + 0.5;
		// Slightly brighter toward the core
		s *= mix(0.55, 1.0, smoothstep(0.45, 0.0, r));

		// Quantize into palette bands
		float steps = float(color_steps);
		s = clamp(floor(s * steps) / (steps - 1.0), 0.0, 1.0);

		vec3 col = s < 0.5
			? mix(deep_color.rgb, mid_color.rgb, s * 2.0)
			: mix(mid_color.rgb, bright_color.rgb, (s - 0.5) * 2.0);

		// Stars that orbit with the swirl and twinkle
		vec2 star_pos = rotate(d, -TIME * speed * 0.3);
		vec2 star_cell = floor(star_pos * pixel_grid);
		float h = hash(star_cell);
		float twinkle = sin(TIME * star_twinkle_speed + h * 6.2831) * 0.5 + 0.5;
		if (h < star_density && twinkle > 0.4) {
			col = mix(col, vec3(0.75, 0.95, 1.0), twinkle);
		}

		COLOR = vec4(col, src.a);
	}
}
