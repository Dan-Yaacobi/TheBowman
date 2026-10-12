shader_type canvas_item;

group_uniforms Recolor;
uniform vec4 target_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float brightness : hint_range(0.0, 3.0) = 1.0;

group_uniforms Detection;
uniform float hue_center : hint_range(0.0, 1.0) = 0.78;
uniform float hue_range : hint_range(0.0, 0.5) = 0.09;
uniform float min_saturation : hint_range(0.0, 1.0) = 0.3;

group_uniforms Flame;
uniform float wobble_px : hint_range(0.0, 4.0) = 1.0;
uniform float noise_scale = 0.15;
uniform float rise_speed = 1.5;
uniform float flicker : hint_range(0.0, 1.0) = 0.2;
uniform float animation_fps = 12.0;
uniform bool pixel_snap = true;

group_uniforms Tongues;
uniform bool tongues_enabled = true;
// How tall the flame licks can grow above the flame, in pixels
uniform int tongue_height_px : hint_range(1, 32) = 8;
// Higher = thinner, more separate tongues
uniform float tongue_width_scale = 0.35;
// Higher = shorter vertical blobs that break off more often
uniform float tongue_break_scale = 0.12;
uniform float tongue_speed = 2.5;
// Lower = fuller, taller fire; higher = sparse, short licks
uniform float tongue_threshold : hint_range(0.0, 1.0) = 0.35;
// Fraction of the tongue height (from the base) that stays solidly attached before breaking up
uniform float base_attach : hint_range(0.01, 1.0) = 0.3;
uniform float tongue_sway_px = 1.5;
// Noise above this (scaled by height) draws the bright inner core
uniform float core_threshold : hint_range(0.0, 1.0) = 0.75;
uniform float core_boost : hint_range(1.0, 2.0) = 1.3;
// How much darker the tips get than the base
uniform float tip_darken : hint_range(0.0, 1.0) = 0.4;
group_uniforms;

varying vec4 modulate_color;

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

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

bool is_fx(vec4 c) {
	if (c.a < 0.01) {
		return false;
	}
	vec3 hsv = rgb2hsv(c.rgb);
	float hue_dist = abs(hsv.x - hue_center);
	hue_dist = min(hue_dist, 1.0 - hue_dist);
	return hue_dist < hue_range && hsv.y > min_saturation;
}

vec4 recolor(vec4 c, float n) {
	vec3 src = rgb2hsv(c.rgb);
	vec3 tgt = rgb2hsv(target_color.rgb);
	float v = src.z * brightness * mix(1.0 - flicker, 1.0 + flicker, n);
	return vec4(hsv2rgb(vec3(tgt.x, src.y * tgt.y, clamp(v, 0.0, 1.0))), c.a);
}

vec4 tongue_at(sampler2D tex, vec2 tps, vec2 px, float t) {
	float sway_n = noise(vec2(px.y * 0.2 + t * tongue_speed * 0.5, px.x * 0.1));
	float n = noise(vec2(px.x * tongue_width_scale, px.y * tongue_break_scale + t * tongue_speed));
	for (int i = 1; i <= tongue_height_px; i++) {
		float h = float(i) / float(tongue_height_px);
		float sway = (sway_n - 0.5) * 2.0 * tongue_sway_px * h;
		if (pixel_snap) {
			sway = round(sway);
		}
		vec2 sample_px = floor(px + vec2(sway, float(i))) + 0.5;
		vec4 src = texture(tex, sample_px * tps);
		// The body blocks flames from rising through it
		if (src.a > 0.01 && !is_fx(src)) {
			return vec4(0.0);
		}
		if (is_fx(src)) {
			float threshold = mix(tongue_threshold, 1.0, h) * smoothstep(0.0, base_attach, h);
			if (n <= threshold) {
				return vec4(0.0);
			}
			vec4 c = recolor(src, n);
			if (n > mix(core_threshold, 1.0, h)) {
				c.rgb = min(c.rgb * core_boost, vec3(1.0));
			} else {
				c.rgb *= mix(1.0, 1.0 - tip_darken, h);
			}
			c.a = 1.0;
			return c;
		}
	}
	return vec4(0.0);
}

void vertex() {
	modulate_color = COLOR;
}

void fragment() {
	float t = floor(TIME * animation_fps) / animation_fps;
	vec2 px = UV / TEXTURE_PIXEL_SIZE;

	float n_side = noise(vec2(px.x * noise_scale, px.y * noise_scale + t * rise_speed));
	float n_rise = noise(vec2(px.x * noise_scale + 17.3, px.y * noise_scale + t * rise_speed * 1.3));

	// Sample sideways and from below, so flame shapes sway and drift upward
	vec2 offset_px = vec2((n_side - 0.5) * 2.0, n_rise) * wobble_px;
	if (pixel_snap) {
		offset_px = round(offset_px);
	}

	vec4 orig = texture(TEXTURE, UV);
	vec4 dist = texture(TEXTURE, UV + offset_px * TEXTURE_PIXEL_SIZE);

	bool orig_fx = is_fx(orig);
	bool orig_empty = orig.a < 0.01;
	vec4 col = orig;

	if (orig_fx || orig_empty) {
		if (is_fx(dist)) {
			col = recolor(dist, n_side);
		} else if (orig_fx && dist.a > 0.01) {
			col = recolor(orig, n_side);
		} else if (orig_fx) {
			col = vec4(0.0);
		}
	}

	if (tongues_enabled && col.a < 0.01) {
		vec4 tongue = tongue_at(TEXTURE, TEXTURE_PIXEL_SIZE, px, t);
		if (tongue.a > 0.0) {
			col = tongue;
		}
	}

	COLOR = col * modulate_color;
}
