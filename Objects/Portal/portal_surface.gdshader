// Goes on the portal sprite. Replaces the flat blue interior with rings that
// flow slowly toward the center, plus a rim along the frame's inner edge.
// Everything that isn't the blue interior is drawn untouched.
shader_type canvas_item;

// 0 = player far away, 1 = player close. Driven by portal.gd.
uniform float proximity : hint_range(0.0, 1.0) = 0.0;
// Ring position, advanced by portal.gd every frame.
uniform float phase = 0.0;

uniform vec4 deep_color : source_color = vec4(0.08, 0.12, 0.40, 1.0);
uniform vec4 mid_color : source_color = vec4(0.18, 0.36, 0.82, 1.0);
uniform vec4 bright_color : source_color = vec4(0.55, 0.80, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.80, 0.95, 1.0, 1.0);

// Where the rings flow toward, in UV (0-1) of the sprite.
uniform vec2 center = vec2(0.5, 0.6);
// Rings per sprite pixel. Lower = wider, calmer rings.
uniform float ring_density = 0.3;
// Radius in sprite pixels of the bright core. Grows a bit when the player is near.
uniform float core_radius = 1.5;

// How finely each sprite pixel is split for the effect.
// 1 = matches the sprite's pixels exactly, 2-4 = finer, 0 = fully smooth.
uniform float sub_pixels = 3.0;
// 0 = hard color bands, 1 = smooth gradient between the colors.
uniform float softness : hint_range(0.0, 1.0) = 0.6;

uniform float idle_rim = 0.3;
uniform float near_rim = 0.9;
// Raise if frame pixels get caught, lower if interior pixels are missed.
uniform float blue_threshold = 0.12;

varying vec4 node_modulate;

void vertex() {
	node_modulate = COLOR;
}

bool is_portal(sampler2D tex, vec2 uv) {
	vec4 c = texture(tex, uv);
	return c.a > 0.5 && (c.b - max(c.r, c.g)) > blue_threshold;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (is_portal(TEXTURE, UV)) {
		vec2 px = TEXTURE_PIXEL_SIZE;

		// Position used for the rings: snapped to a finer grid than the sprite.
		vec2 sample_uv = UV;
		if (sub_pixels > 0.0) {
			vec2 fine = px / sub_pixels;
			sample_uv = (floor(UV / fine) + 0.5) * fine;
		}
		vec2 offset = (sample_uv - center) / px;
		float r = length(offset * vec2(1.0, 0.8));

		// Smooth periodic wave, so rings never pop when they wrap around.
		float w = 0.5 + 0.5 * sin(TAU * (r * ring_density + phase));

		vec3 banded = deep_color.rgb;
		if (w > 0.45) {
			banded = mid_color.rgb;
		}
		if (w > 0.85) {
			banded = bright_color.rgb;
		}
		float g = pow(w, 1.6);
		vec3 smooth_col = g < 0.5
			? mix(deep_color.rgb, mid_color.rgb, g * 2.0)
			: mix(mid_color.rgb, bright_color.rgb, (g - 0.5) * 2.0);
		vec3 col = mix(banded, smooth_col, softness);

		float core_r = core_radius * (1.0 + proximity * 0.6);
		float core = 1.0 - smoothstep(core_r - 0.5 - softness, core_r + 0.5, r);
		col = mix(col, bright_color.rgb, core);

		// Rim stays on the sprite's own pixels, so it lines up with the frame.
		vec2 cell = (floor(UV / px) + 0.5) * px;
		bool edge = !is_portal(TEXTURE, cell + vec2(px.x, 0.0))
			|| !is_portal(TEXTURE, cell - vec2(px.x, 0.0))
			|| !is_portal(TEXTURE, cell + vec2(0.0, px.y))
			|| !is_portal(TEXTURE, cell - vec2(0.0, px.y));
		if (edge) {
			col = mix(col, rim_color.rgb, mix(idle_rim, near_rim, proximity));
		}

		col *= mix(0.9, 1.15, proximity);
		COLOR = vec4(col, tex.a) * node_modulate;
	} else {
		COLOR = tex * node_modulate;
	}
}
