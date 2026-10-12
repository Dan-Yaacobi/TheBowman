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

	COLOR = col * modulate_color;
}