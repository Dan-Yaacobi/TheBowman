shader_type canvas_item;

// Pixel-art ellipse shadow for something about to land.
// It grows and darkens as `progress` goes from 0 (just appeared) to 1 (about to hit).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// One cell per screen pixel: match this to the ColorRect size
uniform vec2 pixel_grid = vec2(24.0, 6.0);
uniform vec4 shadow_color : source_color = vec4(0.05, 0.09, 0.2, 1.0);
uniform vec4 core_color : source_color = vec4(0.02, 0.04, 0.1, 1.0);
// Size and opacity at progress 0; both reach full at progress 1
uniform float min_scale : hint_range(0.0, 1.0) = 0.35;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.25;
uniform float max_alpha : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec2 cell = floor(UV * pixel_grid);
	// -1..1 across the rect, sampled at pixel centres
	vec2 p = (cell + 0.5) / pixel_grid * 2.0 - 1.0;
	float scale = mix(min_scale, 1.0, progress);
	float d = length(p / scale);
	if (d > 1.0) {
		discard;
	}
	vec4 col = d < 0.5 ? core_color : shadow_color;
	col.a = mix(min_alpha, max_alpha, progress);
	COLOR = col;
}
