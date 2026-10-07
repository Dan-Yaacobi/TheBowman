shader_type canvas_item;

// 0 = normal, 1 = fully ablaze. Tween this when the ring activates.
uniform float strength : hint_range(0.0, 1.0) = 1.0;

uniform vec4 ember_color : source_color = vec4(0.55, 0.08, 0.02, 1.0);
uniform vec4 flame_color : source_color = vec4(1.0, 0.45, 0.05, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.9, 0.45, 1.0);

// How much the body itself takes on the fire colors (edges always burn).
uniform float body_tint : hint_range(0.0, 1.0) = 0.45;
// Smaller = bigger flame blobs.
uniform float noise_scale : hint_range(0.05, 1.0) = 0.35;
uniform float rise_speed : hint_range(0.0, 20.0) = 6.0;
// Animation steps per second, keeps the flicker crunchy like pixel art.
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

vec3 fire_ramp(float n) {
	vec3 col = mix(ember_color.rgb, flame_color.rgb, smoothstep(0.3, 0.6, n));
	return mix(col, core_color.rgb, smoothstep(0.65, 0.85, n));
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 col = base.rgb;

	if (base.a > 0.01) {
		// Work in whole texture pixels so the effect stays pixel-crisp.
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
		float t = floor(TIME * fps) / fps;
		float n = fbm(px * noise_scale + vec2(0.0, t * rise_speed));
		vec3 fire = fire_ramp(n);

		// Edge pixels = any neighbor is transparent.
		vec2 s = TEXTURE_PIXEL_SIZE;
		float neighbors = min(
			min(texture(TEXTURE, UV + vec2(s.x, 0.0)).a, texture(TEXTURE, UV - vec2(s.x, 0.0)).a),
			min(texture(TEXTURE, UV + vec2(0.0, s.y)).a, texture(TEXTURE, UV - vec2(0.0, s.y)).a)
		);
		float edge = 1.0 - step(0.01, neighbors);

		// Body: warm tint that keeps the sprite's shading, plus flickering hot spots.
		vec3 body = base.rgb * mix(vec3(1.0), fire * 1.8, body_tint);
		body += core_color.rgb * step(0.78, n) * 0.35;

		// Outline: full fire colors, with dark gaps so it looks like licking flames.
		vec3 rim = mix(ember_color.rgb * 0.6, fire_ramp(n + 0.25), step(0.35, n));

		vec3 burning = mix(body, rim, edge);
		col = mix(base.rgb, burning, strength);
	}

	COLOR = vec4(col, base.a);
}
