shader_type canvas_item;

// 0 = normal, 1 = fully empowered. Veins creep in as this rises.
uniform float strength : hint_range(0.0, 1.0) = 1.0;

uniform vec4 dark_blood : source_color = vec4(0.16, 0.0, 0.03, 1.0);
uniform vec4 blood_color : source_color = vec4(0.62, 0.02, 0.07, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.28, 0.25, 1.0);

// How much the body takes on the blood palette.
uniform float body_tint : hint_range(0.0, 1.0) = 0.5;
// Smaller = longer, sparser veins.
uniform float vein_scale : hint_range(0.05, 1.0) = 0.22;
uniform float vein_width : hint_range(0.01, 0.25) = 0.08;
// Heartbeats per second. Double-thump "lub-dub" pulse.
uniform float heart_rate : hint_range(0.2, 4.0) = 1.3;
// Outline blood slowly runs downward.
uniform float drip_speed : hint_range(0.0, 20.0) = 3.0;
uniform float fps : hint_range(1.0, 30.0) = 12.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float heartbeat(float t) {
	float p = fract(t * heart_rate);
	float lub = max(0.0, 1.0 - p * 7.0);
	float dub = max(0.0, 1.0 - abs(p - 0.22) * 9.0) * 0.6;
	return max(lub, dub);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 col = base.rgb;

	if (base.a > 0.01) {
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
		float t = floor(TIME * fps) / fps;
		float pulse = heartbeat(t);

		// Edge pixels = any neighbor is transparent.
		vec2 s = TEXTURE_PIXEL_SIZE;
		float neighbors = min(
			min(texture(TEXTURE, UV + vec2(s.x, 0.0)).a, texture(TEXTURE, UV - vec2(s.x, 0.0)).a),
			min(texture(TEXTURE, UV + vec2(0.0, s.y)).a, texture(TEXTURE, UV - vec2(0.0, s.y)).a)
		);
		float edge = 1.0 - step(0.01, neighbors);

		// Body: recolor by brightness so shading survives, darkened toward dried blood.
		float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
		vec3 tinted = mix(dark_blood.rgb, blood_color.rgb * 1.6, lum);
		vec3 body = mix(base.rgb, tinted, body_tint);

		// Veins: ridged noise gives thin branching lines. A second noise reveals
		// them progressively as strength rises, so they spread across the body.
		float ridge = abs(value_noise(px * vein_scale) * 2.0 - 1.0);
		float vein = 1.0 - step(vein_width, ridge);
		float reveal = step(value_noise(px * 0.15 + 13.0), strength);
		vec3 vein_col = mix(blood_color.rgb, highlight_color.rgb, pulse);
		body = mix(body, vein_col, vein * reveal);

		// Outline: blood running downward, flaring bright on each heartbeat.
		float n = value_noise(vec2(px.x * 0.6, px.y * 0.3 - t * drip_speed));
		vec3 rim = mix(dark_blood.rgb, blood_color.rgb, step(0.45, n));
		rim = mix(rim, highlight_color.rgb, pulse * step(0.6, n));

		vec3 empowered = mix(body, rim, edge);
		col = mix(base.rgb, empowered, strength);
	}

	COLOR = vec4(col, base.a);
}
