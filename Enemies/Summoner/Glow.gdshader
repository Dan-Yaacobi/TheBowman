shader_type canvas_item;
render_mode unshaded;

uniform float glow_amount : hint_range(0.0, 1.0) = 0.0;
uniform float glow_radius_px : hint_range(0.0, 12.0) = 3.0;
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.1;

// 0 = Plain, 1 = Flame, 2 = Laser
uniform int effect_mode = 0;

// Saturation control (prevents neon bullshit)
uniform float glow_desaturate : hint_range(0.0, 1.0) = 0.4;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.0;

// Colors
uniform vec4 plain_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);

// Flame
uniform vec4 flame_color_a : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform vec4 flame_color_b : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float flame_flicker_speed : hint_range(0.0, 20.0) = 6.0;

// Laser
uniform vec4 laser_color : source_color = vec4(0.3, 0.9, 1.0, 1.0);
uniform float laser_scan_speed : hint_range(0.0, 20.0) = 10.0;
uniform float laser_freq : hint_range(1.0, 60.0) = 30.0;

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1,0));
	float c = hash(i + vec2(0,1));
	float d = hash(i + vec2(1,1));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

vec3 desaturate(vec3 c, float amt) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return mix(c, vec3(l), amt);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 out_col = base;

	// --- Outline detection ---
	float max_neighbor_a = 0.0;
	vec2 px = TEXTURE_PIXEL_SIZE;

	vec2 dirs[8] = vec2[](
		vec2( 1,  0), vec2(-1,  0),
		vec2( 0,  1), vec2( 0, -1),
		vec2( 1,  1), vec2(-1,  1),
		vec2( 1, -1), vec2(-1, -1)
	);

	for (int i = 0; i < 8; i++) {
		vec2 uv2 = UV + dirs[i] * px * glow_radius_px;
		max_neighbor_a = max(max_neighbor_a, texture(TEXTURE, uv2).a);
	}

	float outline =
		step(base.a, edge_threshold) *
		step(edge_threshold, max_neighbor_a);

	// Smooth tween response
	float t = smoothstep(0.0, 1.0, glow_amount);

	// --- Glow color by mode ---
	vec3 glow = plain_color.rgb;

	if (effect_mode == 1) {
		// FLAME
		float n = noise(UV * 18.0 + vec2(0.0, TIME * flame_flicker_speed));
		glow = mix(flame_color_a.rgb, flame_color_b.rgb, n);
	}

	if (effect_mode == 2) {
		// LASER
		float scan = sin(UV.y * laser_freq + TIME * laser_scan_speed);
		glow = laser_color.rgb * (0.4 + abs(scan));
	}

	glow *= glow_intensity * t;
	glow = desaturate(glow, glow_desaturate);

	// Apply only outside
	out_col.rgb += glow * outline;
	out_col.a = max(out_col.a, outline * t);

	COLOR = out_col;
}
