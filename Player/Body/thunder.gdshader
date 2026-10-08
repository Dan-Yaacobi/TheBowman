shader_type canvas_item;

// 0 = normal, 1 = fully charged.
uniform float strength : hint_range(0.0, 1.0) = 1.0;

uniform vec4 charge_color : source_color = vec4(0.12, 0.2, 0.55, 1.0);
uniform vec4 bolt_color : source_color = vec4(0.45, 0.82, 1.0, 1.0);
uniform vec4 spark_color : source_color = vec4(1.0, 1.0, 0.85, 1.0);

uniform float body_tint : hint_range(0.0, 1.0) = 0.4;
// Fraction of body pixels showing static each frame. 0 = none.
uniform float static_density : hint_range(0.0, 0.1) = 0.01;
// Fraction of the outline crackling at any moment.
uniform float arc_density : hint_range(0.0, 1.0) = 0.35;
// Chance per frame that a bolt cuts across the body.
uniform float bolt_chance : hint_range(0.0, 1.0) = 0.25;
// Set to the width of one animation frame so every frame gets its own bolt.
uniform float bolt_spacing : hint_range(4.0, 128.0) = 32.0;
// Chance per frame of a full-body flash.
uniform float flash_chance : hint_range(0.0, 0.5) = 0.06;
// Electricity is jittery: run it faster than the fire.
uniform float fps : hint_range(1.0, 30.0) = 18.0;

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

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 col = base.rgb;

	if (base.a > 0.01) {
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
		// Integer frame index: everything re-rolls each step, no smooth motion.
		float step_id = floor(TIME * fps);

		vec2 s = TEXTURE_PIXEL_SIZE;
		float neighbors = min(
			min(texture(TEXTURE, UV + vec2(s.x, 0.0)).a, texture(TEXTURE, UV - vec2(s.x, 0.0)).a),
			min(texture(TEXTURE, UV + vec2(0.0, s.y)).a, texture(TEXTURE, UV - vec2(0.0, s.y)).a)
		);
		float edge = 1.0 - step(0.01, neighbors);

		// Body: cool, charged tint that keeps the shading.
		float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
		vec3 tinted = mix(charge_color.rgb, bolt_color.rgb, lum);
		vec3 body = mix(base.rgb, tinted, body_tint);

		// Static: single pixels popping on and off.
		float spark = step(1.0 - static_density, hash(px + step_id * 1.731)) * step(0.0001, static_density);
		body = mix(body, bolt_color.rgb, spark);

		// Bolt: a jagged vertical line, repeated every bolt_spacing pixels.
		float has_bolt = step(hash(vec2(step_id, 3.1)), bolt_chance);
		float offset = hash(vec2(step_id, 7.7)) * bolt_spacing;
		float jag = (value_noise(vec2(px.y * 0.5, step_id * 5.0)) - 0.5) * 6.0;
		float line_pos = mod(px.x - offset + jag, bolt_spacing);
		float bolt = has_bolt * (1.0 - step(1.0, line_pos));
		body = mix(body, spark_color.rgb, bolt);

		// Outline: segments arcing on and off at random.
		float n = value_noise(px * 0.35 + vec2(step_id * 7.13, step_id * 3.71));
		float lit = step(1.0 - arc_density, n);
		vec3 rim = mix(charge_color.rgb * 0.7, bolt_color.rgb, lit);
		rim = mix(rim, spark_color.rgb, step(0.92, n));

		vec3 empowered = mix(body, rim, edge);

		// Occasional full-body flash.
		float flash = step(hash(vec2(step_id, 11.3)), flash_chance);
		empowered = mix(empowered, spark_color.rgb, flash * 0.55);

		col = mix(base.rgb, empowered, strength);
	}

	COLOR = vec4(col, base.a);
}
