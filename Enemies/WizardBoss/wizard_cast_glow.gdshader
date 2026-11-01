shader_type canvas_item;

// Spell-cast glow for wizard sprites: while casting, the hands heat up and a stepped
// pixel-art halo spreads around them, spilling a little light onto the robe.
// One shader for every wizard: give each its own colours on the material.
// glow_amount is driven from code (0 = not casting, 1 = full glow).
// Works on sprite sheets: set frames_h / frames_v to the Sprite2D's hframes / vframes.

group_uniforms Glow;
uniform float glow_amount : hint_range(0.0, 1.0) = 0.0;
// Halo and light-spill colour
uniform vec4 glow_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
// The hottest colour the hands themselves turn
uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.65, 1.0);
// Halo reach around each hand, in texture pixels
uniform int glow_radius_px : hint_range(1, 16) = 8;
// How strongly the halo tints robe pixels it overlaps (0 = only empty space glows)
uniform float spill : hint_range(0.0, 1.0) = 0.35;
// Halo opacity of the inner / middle / outer band
uniform vec3 band_alpha = vec3(0.85, 0.5, 0.22);

group_uniforms Hands;
// Pixels at least this bright count as hands (the robe is darker)
uniform float hand_threshold : hint_range(0.0, 1.0) = 0.7;
// A bright pixel only counts as hand if this many of its 24 nearest pixels are bright too.
// Filters out small bright details (buckles, studs) so only the hands glow.
uniform int hand_min_neighbors : hint_range(0, 24) = 9;

group_uniforms Pulse;
uniform float pulse_speed = 6.0;
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.15;

group_uniforms Sheet;
uniform int frames_h = 13;
uniform int frames_v = 5;
group_uniforms;

// The sprite's modulate (teleport fades, hit flashes) is kept and applied last
varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

bool is_bright(vec4 c) {
	return c.a > 0.5 && luma(c.rgb) >= hand_threshold;
}

// A bright pixel inside a big enough bright clump (a hand, not a buckle)
bool is_hand(sampler2D tex, vec2 uv, vec2 texel, vec2 frame_min, vec2 frame_max) {
	if (!is_bright(texture(tex, uv))) {
		return false;
	}
	int count = 0;
	for (int dy = -2; dy <= 2; dy++) {
		for (int dx = -2; dx <= 2; dx++) {
			if (dx == 0 && dy == 0) {
				continue;
			}
			vec2 n = uv + vec2(float(dx), float(dy)) * texel;
			if (any(lessThan(n, frame_min)) || any(greaterThanEqual(n, frame_max))) {
				continue;
			}
			if (is_bright(texture(tex, n))) {
				count++;
			}
		}
	}
	return count >= hand_min_neighbors;
}

void fragment() {
	vec4 orig = texture(TEXTURE, UV);
	if (glow_amount <= 0.001) {
		COLOR = orig * modulate_color;
	} else {
		// Bounds of the current frame on the sheet, so the halo never reads a neighbouring frame
		vec2 frame_size = vec2(1.0 / float(frames_h), 1.0 / float(frames_v));
		vec2 frame_min = floor(UV / frame_size) * frame_size;
		vec2 frame_max = frame_min + frame_size;

		// Distance (in pixels) to the nearest hand pixel, searched on rings around this pixel
		float nearest = 1000.0;
		if (is_hand(TEXTURE, UV, TEXTURE_PIXEL_SIZE, frame_min, frame_max)) {
			nearest = 0.0;
		} else {
			for (int r = 1; r <= 16; r++) {
				if (r > glow_radius_px || nearest < 1000.0) {
					break;
				}
				for (int k = 0; k < 16; k++) {
					float a = float(k) * 0.3926991;
					vec2 offset = round(vec2(cos(a), sin(a)) * float(r));
					vec2 uv = UV + offset * TEXTURE_PIXEL_SIZE;
					if (any(lessThan(uv, frame_min)) || any(greaterThanEqual(uv, frame_max))) {
						continue;
					}
					if (is_hand(TEXTURE, uv, TEXTURE_PIXEL_SIZE, frame_min, frame_max)) {
						nearest = min(nearest, length(offset));
					}
				}
			}
		}

		float pulse = 1.0 + pulse_amount * sin(TIME * pulse_speed);
		float amount = clamp(glow_amount * pulse, 0.0, 1.0);
		vec4 col = orig;

		if (nearest == 0.0) {
			// The hand itself heats toward the core colour
			col.rgb = mix(orig.rgb, core_color.rgb, amount * 0.8);
		} else if (nearest <= float(glow_radius_px)) {
			// Stepped halo bands: inner, middle, outer
			float t = nearest / float(glow_radius_px);
			float band = t <= 0.34 ? band_alpha.x : (t <= 0.67 ? band_alpha.y : band_alpha.z);
			vec3 halo = t <= 0.34 ? mix(glow_color.rgb, core_color.rgb, 0.5) : glow_color.rgb;
			float strength = band * amount;
			if (orig.a < 0.01) {
				col = vec4(halo, strength);
			} else {
				col.rgb = mix(orig.rgb, halo, strength * spill);
			}
		}
		COLOR = col * modulate_color;
	}
}
