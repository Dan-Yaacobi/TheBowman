shader_type canvas_item;

// Danger-zone circle: a fill grows from the centre and reaches the rim when the attack lands.
// progress: 0 = just appeared, 1 = the fill touches the rim (attack lands)
// pulse:    0..1 brightness of the rim, driven from script so it can speed up smoothly
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
// One cell per screen pixel: match this to the ColorRect size (diameter x diameter)
uniform vec2 pixel_grid = vec2(160.0, 160.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform vec4 rim_dim_color : source_color = vec4(0.62, 0.12, 0.06, 1.0);
uniform vec4 outline_color : source_color = vec4(0.18, 0.03, 0.02, 1.0);
uniform vec4 fill_color : source_color = vec4(0.95, 0.3, 0.08, 0.2);
uniform vec4 front_color : source_color = vec4(1.0, 0.7, 0.25, 0.6);
// Rim thickness and the bright band at the edge of the growing fill, in pixels
uniform float rim_width = 2.0;
uniform float front_width = 2.0;

void fragment() {
	vec2 cell = floor(UV * pixel_grid);
	vec2 p = (cell + 0.5) / pixel_grid * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float radius_px = pixel_grid.x * 0.5;
	float from_rim = (1.0 - r) * radius_px;

	vec4 col = vec4(0.0);
	if (r <= progress) {
		col = fill_color;
		if ((progress - r) * radius_px < front_width) {
			col = front_color;
		}
	}
	if (from_rim < rim_width + 1.0) {
		col = mix(rim_dim_color, rim_color, pulse);
	}
	if (from_rim < 1.0) {
		col = outline_color;
	}
	if (col.a <= 0.0) {
		discard;
	}
	COLOR = col;
}
