// Goes on the quest board sprite.
// Always: the lantern flickers gently.
// Player near (proximity -> 1): the lantern brightens, a thin outline fades in,
// and a light shine sweeps across the papers and banner emblems every few seconds.
shader_type canvas_item;

// 0 = player far away, 1 = player close. Driven by script.
uniform float proximity : hint_range(0.0, 1.0) = 0.0;

group_uniforms Lantern;
uniform float idle_flicker = 0.08;
uniform float near_flicker = 0.15;
uniform float near_lantern_boost = 0.35;
uniform vec4 lantern_tint : source_color = vec4(1.0, 0.85, 0.5, 1.0);

group_uniforms Shine;
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform float shine_strength = 0.55;
// Seconds between sweeps, and how long one sweep takes.
uniform float sweep_interval = 4.0;
uniform float sweep_duration = 0.7;
// Width of the shine band, as a fraction of the sprite's diagonal.
uniform float sweep_width = 0.04;

group_uniforms Outline;
uniform vec4 outline_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);

group_uniforms Detection;
// Tune these if the wrong pixels react. Turn on debug_masks to see what's detected:
// red = lantern, green = paper, blue = emblems.
uniform bool debug_masks = false;
uniform float lantern_min_red = 0.75;
uniform float lantern_max_blue = 0.45;
uniform float paper_min_brightness = 0.62;
uniform float emblem_min_blue = 0.6;
uniform float emblem_blue_margin = 0.12;

varying vec4 node_modulate;

void vertex() {
	node_modulate = COLOR;
}

float lantern_mask(vec3 c) {
	return (c.r > lantern_min_red && c.b < lantern_max_blue && c.r - c.b > 0.4) ? 1.0 : 0.0;
}

float paper_mask(vec3 c) {
	float bright = (c.r + c.g + c.b) / 3.0;
	float warmth = c.r - c.b;
	return (bright > paper_min_brightness && warmth > 0.08 && warmth < 0.35 && c.g > c.b) ? 1.0 : 0.0;
}

float emblem_mask(vec3 c) {
	return (c.b > emblem_min_blue && c.b - max(c.r, c.g) > emblem_blue_margin) ? 1.0 : 0.0;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;

	if (tex.a < 0.5) {
		// Outline: transparent pixel touching the sprite.
		float n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a
			+ texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		float outline = step(0.5, n) * proximity * outline_color.a;
		COLOR = vec4(outline_color.rgb, outline) * node_modulate;
	} else {
		vec3 col = tex.rgb;
		float lantern = lantern_mask(col);
		float paper = paper_mask(col);
		float emblem = emblem_mask(col);

		// Lantern flicker: a few sines layered so it never looks like a clean pulse.
		float flicker = 0.5 * sin(TIME * 7.3) + 0.3 * sin(TIME * 13.1) + 0.2 * sin(TIME * 23.7);
		float amount = mix(idle_flicker, near_flicker, proximity);
		float lantern_light = 1.0 + flicker * amount + near_lantern_boost * proximity;
		vec3 lit = col * lantern_light + lantern_tint.rgb * near_lantern_boost * proximity * 0.3;
		col = mix(col, lit, lantern);

		// Shine sweep across papers and emblems, snapped to the sprite's pixels.
		vec2 pix = floor(UV / px);
		vec2 sprite_size = 1.0 / px;
		float diag = (pix.x + pix.y) / (sprite_size.x + sprite_size.y);
		float progress = mod(TIME, sweep_interval) / sweep_duration;
		float band = 0.0;
		if (progress <= 1.0) {
			float pos = mix(-sweep_width, 1.0 + sweep_width, progress);
			band = step(abs(diag - pos), sweep_width);
		}
		float shine = band * max(paper, emblem) * proximity * shine_strength;
		col = mix(col, shine_color.rgb, shine);

		if (debug_masks) {
			col = vec3(lantern, paper, emblem);
		}
		COLOR = vec4(col, tex.a) * node_modulate;
	}
}
