shader_type canvas_item;

// Put this on a ColorRect. The bottom edge of the rect is where the fire starts,
// so line it up with the island surface. The rect's height is the tallest the flames can get.

group_uniforms Shape;
// 0 = nothing, 1 = full fire. Animate this to grow the fire from a flat line and to put it out.
uniform float burn_amount : hint_range(0.0, 1.0) = 1.0;
// Lowest and highest flame height, as a fraction of the rect's height
uniform float min_height : hint_range(0.0, 1.0) = 0.35;
uniform float max_height : hint_range(0.0, 1.0) = 0.95;
// Higher = more, narrower flame columns along the line
uniform float column_scale = 6.0;
// How ragged the flame edges are
uniform float turbulence : hint_range(0.0, 2.0) = 0.9;
// Fraction of the width over which the flames shrink at the left and right ends
uniform float edge_fade : hint_range(0.0, 0.5) = 0.12;

group_uniforms Motion;
uniform float rise_speed = 2.2;
uniform float sway : hint_range(0.0, 0.2) = 0.04;
uniform float animation_fps = 12.0;

group_uniforms Pixels;
// How many pixels across and up the rect is drawn with; match your game's pixel scale
uniform vec2 pixel_grid = vec2(48.0, 24.0);

group_uniforms Colors;
uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform vec4 inner_color : source_color = vec4(1.0, 0.7, 0.18, 1.0);
uniform vec4 outer_color : source_color = vec4(0.91, 0.31, 0.1, 1.0);
uniform vec4 edge_color : source_color = vec4(0.48, 0.1, 0.07, 1.0);
// Band thresholds, from the hot core outward
uniform float core_threshold : hint_range(0.0, 1.5) = 0.85;
uniform float inner_threshold : hint_range(0.0, 1.5) = 0.55;
uniform float outer_threshold : hint_range(0.0, 1.5) = 0.28;
uniform float edge_threshold : hint_range(0.0, 1.5) = 0.1;
group_uniforms;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		total += noise(p) * amp;
		p *= 2.0;
		amp *= 0.5;
	}
	return total / 0.875;
}

void fragment() {
	float t = floor(TIME * animation_fps) / animation_fps;

	// Snap to the pixel grid so the fire reads as pixel art
	vec2 uv = (floor(UV * pixel_grid) + 0.5) / pixel_grid;
	float height_up = 1.0 - uv.y;

	// Sway: columns lean sideways more the higher they go
	float sway_n = noise(vec2(uv.y * 4.0 + t * 1.5, uv.x * 3.0)) - 0.5;
	float x = uv.x + sway_n * sway * height_up * 2.0;

	// Flame height varies along the line and shifts over time
	float column = fbm(vec2(x * column_scale, t * 0.6));
	float ends = smoothstep(0.0, edge_fade, uv.x) * smoothstep(0.0, edge_fade, 1.0 - uv.x);
	float h = mix(min_height, max_height, column) * burn_amount * ends;

	// Flame body: noise scrolling upward, eaten away more the higher it gets
	float body = fbm(vec2(x * column_scale * 2.0, uv.y * 5.0 + t * rise_speed));
	float heat = (1.0 - height_up / max(h, 0.001)) + (body - 0.5) * turbulence;

	vec4 col = vec4(0.0);
	if (heat > core_threshold) {
		col = core_color;
	} else if (heat > inner_threshold) {
		col = inner_color;
	} else if (heat > outer_threshold) {
		col = outer_color;
	} else if (heat > edge_threshold) {
		col = edge_color;
	}

	COLOR = col;
}
