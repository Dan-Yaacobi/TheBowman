shader_type canvas_item;

// Pixel-art ice bubble around a caster.
// form:   0 -> 1 while the shell grows in
// cracks: 0 = intact, 1 = about to shatter (more crack lines appear as it rises)
// hit_flash: 1 right after a hit, fades back to 0
uniform float form : hint_range(0.0, 1.0) = 1.0;
uniform float cracks : hint_range(0.0, 1.0) = 0.0;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
// One cell per art pixel: match this to the ColorRect size
uniform vec2 pixel_grid = vec2(72.0, 88.0);
uniform vec4 fill_color : source_color = vec4(0.6, 0.88, 1.0, 0.25);
uniform vec4 rim_color : source_color = vec4(0.78, 0.96, 1.0, 0.85);
uniform vec4 outline_color : source_color = vec4(0.12, 0.24, 0.45, 1.0);
uniform vec4 crack_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);
// Rim thickness in pixels
uniform float rim_width = 4.0;
// How many crack lines exist at cracks = 1
uniform int max_cracks = 7;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * pixel_grid);
	vec2 p = (cell + 0.5) / pixel_grid * 2.0 - 1.0;
	float grow = max(form, 0.001);
	float r = length(p) / grow;
	if (r > 1.0) {
		discard;
	}

	float radius_px = min(pixel_grid.x, pixel_grid.y) * 0.5 * grow;
	float px_from_edge = (1.0 - r) * radius_px;

	vec4 col = fill_color;
	if (px_from_edge < rim_width) {
		col = rim_color;
	}

	// Shine arc on the upper left
	vec2 hl = p / grow - vec2(-0.38, -0.42);
	float hl_len = length(hl);
	if (hl_len < 0.2 && hl_len > 0.11 && hl.x + hl.y < 0.05) {
		col = shine_color;
	}

	// Jagged crack lines running in from the rim; more show up as `cracks` rises
	float ang = atan(p.y, p.x);
	float visible_cracks = cracks * float(max_cracks);
	for (int i = 0; i < max_cracks; i++) {
		float fi = float(i);
		if (fi >= visible_cracks) {
			continue;
		}
		float a0 = hash(vec2(fi, 1.0)) * 6.2831 - 3.1416;
		float reach = 0.35 + 0.55 * hash(vec2(fi, 2.0));
		float wobble = (hash(vec2(fi, floor(r * 9.0))) - 0.5) * 0.3;
		float da = abs(mod(ang - a0 - wobble + 3.1416, 6.2831) - 3.1416);
		if (r > 1.0 - reach && da * r * radius_px < 0.75) {
			col = crack_color;
		}
	}

	if (px_from_edge < 1.0) {
		col = outline_color;
	}

	col.rgb = mix(col.rgb, vec3(1.0), hit_flash);
	col.a = max(col.a, hit_flash * 0.6);
	COLOR = col;
}
