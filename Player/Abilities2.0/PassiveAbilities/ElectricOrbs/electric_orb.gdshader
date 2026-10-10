shader_type canvas_item;
// Premultiplied alpha lets the glow brighten what's behind it, like real light.
render_mode blend_premul_alpha;

// White-hot center -> blue body -> violet tips.
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform vec4 glow_color : source_color = vec4(0.35, 0.72, 1.0, 1.0);
uniform vec4 tip_color : source_color = vec4(0.62, 0.6, 1.0, 1.0);

// Three layers of bolts: long main bolts, branches, and fine hairline crackle.
uniform int main_count : hint_range(0, 40) = 16;
uniform int branch_count : hint_range(0, 100) = 40;
uniform int hair_count : hint_range(0, 200) = 80;
// How far bolts wander sideways (orb units). Grows toward the tips.
uniform float jag_amount : hint_range(0.0, 0.3) = 0.1;
// Line widths in screen pixels, so they stay crisp at any sprite scale.
uniform float core_width : hint_range(0.5, 6.0) = 1.4;
uniform float glow_width : hint_range(0.5, 12.0) = 3.0;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.0;
// The bright bloom in the middle.
uniform float bloom_size : hint_range(0.0, 0.5) = 0.13;
uniform float bloom_strength : hint_range(0.0, 3.0) = 1.4;
uniform float hot_size : hint_range(0.0, 0.3) = 0.07;
// How fast bolts morph into new positions and shapes (continuous, no jumps)...
uniform float layout_rate : hint_range(0.0, 10.0) = 2.0;
// ...while the fine jitter re-rolls this often (crackle).
uniform float crackle_fps : hint_range(1.0, 60.0) = 14.0;
// Slow spin of the whole thing, radians per second.
uniform float rotate_speed : hint_range(-5.0, 5.0) = 0.3;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Straight lines between random points: sharp corners, like real lightning.
// Returns the offset in x and its slope in y.
vec2 zigzag(float x, float seed) {
	float i = floor(x);
	float a = hash(vec2(i, seed)) * 2.0 - 1.0;
	float b = hash(vec2(i + 1.0, seed)) * 2.0 - 1.0;
	return vec2(mix(a, b, fract(x)), b - a);
}

// One layer of radial bolts. Returns (core, glow) intensity at this pixel.
// Each bolt gets its own start radius, length, angle and zigzag shape.
vec2 bolt_layer(float r, float ang, float px, float count, vec2 start_range, vec2 len_range,
		float spread, float freq, float salt, float width, float glow_w, float layout_time, float crackle_step) {
	float core = 0.0;
	float glow = 0.0;
	float id0 = floor(ang / TAU * count);
	// Blend between the current layout and the next one, eased, so bolts morph continuously.
	float lt = floor(layout_time);
	float lf = fract(layout_time);
	lf = lf * lf * (3.0 - 2.0 * lf);
	// A bolt can wander into its neighbors' slice, so check them too.
	for (int k = -1; k <= 1; k++) {
		float id = id0 + float(k);
		// Wrap the id so bolts crossing the -PI/PI seam keep the same identity.
		float wid = mod(id, count);
		float seed_a = salt + wid * 17.31 + lt * 5.13;
		float seed_b = salt + wid * 17.31 + (lt + 1.0) * 5.13;
		float crackle_seed = salt + wid * 17.31 + crackle_step * 3.7;

		float jitter = mix(hash(vec2(seed_a, 1.0)), hash(vec2(seed_b, 1.0)), lf);
		float center = (id + 0.5 + (jitter - 0.5) * 0.8) / count * TAU;
		float r0 = mix(start_range.x, start_range.y, mix(hash(vec2(seed_a, 2.0)), hash(vec2(seed_b, 2.0)), lf));
		float r1 = r0 + mix(len_range.x, len_range.y, mix(hash(vec2(seed_a, 3.0)), hash(vec2(seed_b, 3.0)), lf));
		if (r < r0 || r > r1) {
			continue;
		}
		float along = (r - r0) / (r1 - r0);
		float sp = spread * (0.15 + along);

		// Big kinks morph smoothly with the layout; small kinks crackle every frame.
		float x = (r - r0) * freq;
		vec2 big = mix(zigzag(x, seed_a), zigzag(x, seed_b), lf);
		vec2 small = zigzag(x * 2.7, crackle_seed);
		float off = big.x + small.x * 0.35;
		float slope = (big.y + small.y * 0.35 * 2.7) * freq * sp;

		float perp = (ang - center) * r;
		float dist = abs(perp - off * sp) / sqrt(1.0 + slope * slope);
		float dpx = dist / px;

		// Fade in at the root, thin out toward the tip.
		float fade = smoothstep(0.0, 0.1, along) * pow(1.0 - along, 0.8);
		float flicker = mix(0.5, 1.0, hash(vec2(crackle_seed, 4.0)));
		core = max(core, (1.0 - smoothstep(width * 0.5, width, dpx)) * fade * flicker);
		glow += exp(-dpx / glow_w) * fade * flicker;
	}
	return vec2(core, glow);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	// Spin by offsetting the angle, wrapped back into -PI..PI.
	float ang = mod(atan(p.y, p.x) - TIME * rotate_speed + PI, TAU) - PI;
	// How many orb units one screen pixel covers.
	float px = max(fwidth(p.x), fwidth(p.y));
	float layout_time = TIME * layout_rate;
	float crackle_step = floor(TIME * crackle_fps);

	vec2 main_b = bolt_layer(r, ang, px, float(main_count), vec2(0.03, 0.08), vec2(0.55, 0.9),
		jag_amount, 10.0, 11.0, core_width, glow_width, layout_time, crackle_step);
	vec2 branch_b = bolt_layer(r, ang, px, float(branch_count), vec2(0.15, 0.55), vec2(0.12, 0.35),
		jag_amount * 0.7, 16.0, 23.0, core_width * 0.75, glow_width * 0.6, layout_time, crackle_step);
	vec2 hair_b = bolt_layer(r, ang, px, float(hair_count), vec2(0.1, 0.7), vec2(0.05, 0.18),
		jag_amount * 0.5, 24.0, 37.0, core_width * 0.5, glow_width * 0.4, layout_time, crackle_step);

	float core = min(main_b.x + branch_b.x * 0.8 + hair_b.x * 0.5, 1.0);
	float glow = (main_b.y + branch_b.y * 0.6 + hair_b.y * 0.3) * glow_intensity;

	// Lines shift from white near the center, to blue, to violet at the tips.
	vec3 line_col = mix(core_color.rgb, glow_color.rgb, smoothstep(0.05, 0.45, r));
	line_col = mix(line_col, tip_color.rgb, smoothstep(0.45, 0.95, r));

	// Central bloom: a wide blue haze with a white-hot middle.
	float hot = 1.0 - smoothstep(0.0, max(hot_size, 0.001), r);
	float bloom = exp(-r / max(bloom_size, 0.001)) * bloom_strength;

	vec3 col = line_col * core
		+ mix(glow_color.rgb, tip_color.rgb, smoothstep(0.4, 0.9, r)) * glow * 0.6
		+ mix(glow_color.rgb, core_color.rgb, hot) * bloom
		+ core_color.rgb * hot;
	float alpha = clamp(core + glow * 0.35 + bloom * 0.6 + hot, 0.0, 1.0);

	// Fade before the sprite's edge so nothing shows a hard square cutoff.
	float edge_fade = 1.0 - smoothstep(0.85, 1.0, r);
	COLOR = vec4(col * edge_fade, alpha * edge_fade);
}
