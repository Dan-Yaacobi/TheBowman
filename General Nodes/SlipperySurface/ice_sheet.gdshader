shader_type canvas_item;

// 0 = no ice, 1 = full sheet. The sheet grows outward from the centre and melts back in.
uniform float ice_amount : hint_range(0.0, 1.0) = 1.0;
// One cell per screen pixel: match this to the ColorRect size
uniform vec2 pixel_grid = vec2(44.0, 6.0);
uniform vec4 rim_color : source_color = vec4(0.93, 0.99, 1.0, 1.0);
uniform vec4 base_color : source_color = vec4(0.62, 0.86, 0.96, 0.9);
uniform vec4 shade_color : source_color = vec4(0.36, 0.62, 0.84, 0.9);
uniform vec4 edge_color : source_color = vec4(0.16, 0.3, 0.48, 1.0);
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Diagonal glint that sweeps across the ice
uniform float shine_speed = 0.5;
uniform float shine_width = 0.06;
// Chance per column that the top edge starts one pixel lower (jagged surface)
uniform float jagged_chance : hint_range(0.0, 1.0) = 0.3;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * pixel_grid);
	vec2 puv = (cell + 0.5) / pixel_grid;

	// Grow / melt from the centre
	float half_width = ice_amount * 0.5;
	if (abs(puv.x - 0.5) > half_width) {
		discard;
	}

	// Jagged top edge
	float top_row = hash(cell.x + 7.0) < jagged_chance ? 1.0 : 0.0;
	if (cell.y < top_row) {
		discard;
	}

	vec4 col = base_color;
	if (cell.y >= pixel_grid.y - 2.0) {
		col = shade_color;
	}
	if (cell.y == top_row) {
		col = rim_color;
	}

	// Darker cap on the outermost columns of the current sheet
	float cells_from_edge = (half_width - abs(puv.x - 0.5)) * pixel_grid.x;
	if (cells_from_edge < 1.0) {
		col = edge_color;
	}

	// Sweeping glint
	float s = fract(puv.x - puv.y * 0.35 - TIME * shine_speed);
	if (s < shine_width && cell.y > top_row && cells_from_edge >= 1.0) {
		col = shine_color;
	}

	COLOR = col;
}
