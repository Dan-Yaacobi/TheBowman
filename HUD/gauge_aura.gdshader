shader_type canvas_item;

// 0 = off, 1 = full flames. Tween this when the gauge fills.
uniform float strength : hint_range(0.0, 1.0) = 1.0;

// Set from charge_color by the Gauge script.
uniform vec4 glow_color : source_color = vec4(1.0, 0.6, 0.2, 1.0);

// Set by the Gauge script: the aura rect's size, and where the bar sits inside it.
uniform vec2 rect_size = vec2(32.0, 64.0);
uniform vec2 bar_min = vec2(8.0, 16.0);
uniform vec2 bar_max = vec2(24.0, 56.0);

// How far the flames reach out from the bar, in pixels (before noise).
uniform float glow_reach : hint_range(1.0, 16.0) = 4.0;
// Below 1 stretches flames upward above the bar. 0.4 = ~2.5x taller on top.
uniform float top_squash : hint_range(0.1, 1.0) = 0.4;
// Shrinks the flame source inward if the bar's art has transparent padding.
uniform float inset : hint_range(0.0, 8.0) = 0.0;

uniform float noise_scale : hint_range(0.05, 1.0) = 0.3;
uniform float rise_speed : hint_range(0.0, 20.0) = 7.0;
uniform float hot_brightness : hint_range(0.0, 1.0) = 0.6;
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

float fbm(vec2 p) {
	return value_noise(p) * 0.65 + value_noise(p * 2.1) * 0.35;
}

void fragment() {
	// Whole-pixel coordinates across the aura rect.
	vec2 px = floor(UV * rect_size);
	float t = floor(TIME * fps) / fps;

	// Distance from the bar's rectangle, stretched so flames climb higher on top.
	vec2 center = (bar_min + bar_max) * 0.5;
	vec2 half_size = (bar_max - bar_min) * 0.5 - inset;
	vec2 dv = max(abs(px + 0.5 - center) - half_size, vec2(0.0));
	if (px.y + 0.5 < center.y) {
		dv.y *= top_squash;
	}
	float dist = length(dv);

	// Rising noise makes the reach ragged, so the edge licks upward.
	float n = fbm(px * noise_scale + vec2(0.0, t * rise_speed));
	float reach = glow_reach * (0.4 + n);
	float heat = 1.0 - dist / reach;

	vec3 hot = mix(glow_color.rgb, vec3(1.0), hot_brightness);
	vec3 col = glow_color.rgb;
	float alpha = 0.0;
	if (heat > 0.66) {
		col = hot;
		alpha = 1.0;
	} else if (heat > 0.33) {
		alpha = 0.85;
	} else if (heat > 0.0) {
		col = glow_color.rgb * 0.7;
		alpha = 0.5;
	}

	COLOR = vec4(col, alpha * strength);
}
