shader_type canvas_item;

// 0 = normal, 1 = fully soul-empowered.
uniform float strength : hint_range(0.0, 1.0) = 1.0;

// Sampled from the soul sprite: mint body, deep teal shade, near-white glow.
uniform vec4 soul_dark : source_color = vec4(0.09, 0.42, 0.36, 1.0);
uniform vec4 soul_color : source_color = vec4(0.42, 0.91, 0.73, 1.0);
uniform vec4 soul_core : source_color = vec4(0.86, 1.0, 0.95, 1.0);

uniform float body_tint : hint_range(0.0, 1.0) = 0.6;
// Max transparency the body flickers to. Ghostly, but keep him readable.
uniform float transparency : hint_range(0.0, 0.8) = 0.3;
// Horizontal wave through the sprite, in whole pixels.
uniform float wobble_pixels : hint_range(0.0, 3.0) = 1.0;
uniform float wobble_speed : hint_range(0.0, 10.0) = 3.0;
// Wisps rising along the outline.
uniform float rise_speed : hint_range(0.0, 20.0) = 4.0;
uniform float fps : hint_range(1.0, 30.0) = 10.0;

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
	vec2 s = TEXTURE_PIXEL_SIZE;
	float t = floor(TIME * fps) / fps;

	// Ghostly wobble: each row shifts sideways by whole pixels on a slow wave.
	float row = floor(UV.y / s.y);
	float shift = round(sin(row * 0.5 + t * wobble_speed) * wobble_pixels * strength);
	vec2 uv = UV + vec2(shift * s.x, 0.0);

	vec4 base = texture(TEXTURE, uv);
	vec3 col = base.rgb;
	float alpha = base.a;

	if (base.a > 0.01) {
		vec2 px = floor(uv / s);

		float neighbors = min(
			min(texture(TEXTURE, uv + vec2(s.x, 0.0)).a, texture(TEXTURE, uv - vec2(s.x, 0.0)).a),
			min(texture(TEXTURE, uv + vec2(0.0, s.y)).a, texture(TEXTURE, uv - vec2(0.0, s.y)).a)
		);
		float edge = 1.0 - step(0.01, neighbors);

		// Body: recolor into the soul palette by brightness.
		float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
		vec3 ramp = mix(soul_dark.rgb, soul_color.rgb, smoothstep(0.1, 0.5, lum));
		ramp = mix(ramp, soul_core.rgb, smoothstep(0.6, 0.9, lum));
		vec3 body = mix(base.rgb, ramp, body_tint);

		// Slow rising mist inside the body.
		float mist = value_noise(px * 0.3 + vec2(0.0, t * rise_speed * 0.5));
		body = mix(body, soul_core.rgb, step(0.8, mist) * 0.4);

		// Outline: glowing wisps drifting upward.
		float n = value_noise(vec2(px.x * 0.5, px.y * 0.4 + t * rise_speed));
		vec3 rim = mix(soul_color.rgb, soul_core.rgb, step(0.65, n));

		vec3 empowered = mix(body, rim, edge);
		col = mix(base.rgb, empowered, strength);

		// Body flickers translucent; the outline stays solid so the silhouette reads.
		float fade = transparency * (0.5 + 0.5 * mist) * (1.0 - edge);
		alpha = base.a * (1.0 - fade * strength);
	}

	COLOR = vec4(col, alpha);
}
