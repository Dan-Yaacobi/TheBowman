shader_type canvas_item;

// Turns a small round "essence" sprite into a pixel-art soul flame / wisp.
// Put it on a Sprite2D (centered = true, texture filter = Nearest).
// Feed `velocity` (pixels/sec, smoothed) from script and the tail streams
// behind the direction of travel; at rest it burns straight up.

group_uniforms Canvas;
// half-size of the drawn quad in orb radii; must fit the longest stretched tail
uniform float canvas_radius : hint_range(2.0, 12.0) = 7.5;
uniform float pixel_scale : hint_range(0.5, 4.0) = 1.0;

group_uniforms Motion;
uniform vec2 velocity = vec2(0.0);
// below this speed (px/s) the flame burns upright
uniform float trail_start_speed : hint_range(0.0, 500.0) = 20.0;
// at this speed the tail points fully opposite the movement
uniform float trail_full_speed : hint_range(1.0, 1000.0) = 150.0;
// extra tail length at full speed (1.0 = double length)
uniform float max_stretch : hint_range(0.0, 3.0) = 1.0;
// tail gets thinner at speed
uniform float speed_taper : hint_range(0.0, 4.0) = 1.5;

group_uniforms Shape;
uniform float body_radius : hint_range(0.3, 1.5) = 0.9;
uniform float flame_height : hint_range(1.0, 5.0) = 3.4;
uniform float taper : hint_range(0.5, 4.0) = 1.6;
uniform float curl_amount : hint_range(0.0, 1.0) = 0.35;
uniform float curl_frequency : hint_range(0.0, 5.0) = 1.8;
uniform float noise_scale : hint_range(0.2, 5.0) = 1.6;
uniform float noise_strength : hint_range(0.0, 1.5) = 0.55;
uniform float speed : hint_range(0.0, 5.0) = 1.2;
uniform float flicker : hint_range(0.0, 0.5) = 0.08;
uniform float tail_cooling : hint_range(0.0, 1.0) = 0.45;

group_uniforms Colors;
uniform vec4 edge_color : source_color = vec4(0.25, 0.06, 0.58, 1.0);
uniform vec4 outer_color : source_color = vec4(0.50, 0.18, 0.92, 1.0);
uniform vec4 mid_color : source_color = vec4(0.78, 0.50, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.92, 1.0, 1.0);
// intensity thresholds for outer / mid / core bands
uniform vec3 bands = vec3(0.18, 0.42, 0.68);
// how much the original orb texture brightens / tints the core
uniform float orb_boost : hint_range(0.0, 2.0) = 1.0;
uniform float orb_color_mix : hint_range(0.0, 1.0) = 0.25;

group_uniforms Embers;
uniform float ember_density : hint_range(0.5, 6.0) = 2.2;
uniform float ember_chance : hint_range(0.0, 1.0) = 0.18;
uniform float ember_speed : hint_range(0.0, 4.0) = 1.0;
uniform float ember_size : hint_range(0.02, 0.5) = 0.14;
uniform float ember_range : hint_range(1.0, 5.0) = 2.4;
group_uniforms;

varying vec4 v_modulate;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		v += amp * value_noise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return v / 0.875;
}

void vertex() {
	v_modulate = COLOR;
	// symmetric quad around the orb so the tail can point any direction
	VERTEX *= canvas_radius;
}

void fragment() {
	// p = position in "orb space": the original orb covers -1..1, y points down
	vec2 texel = 2.0 * TEXTURE_PIXEL_SIZE * pixel_scale;
	vec2 p = (UV - 0.5) * 2.0 * canvas_radius;
	p = (floor(p / texel) + 0.5) * texel; // snap to the pixel grid
	float t = TIME * speed;

	// tail direction: rotate from upright toward "opposite of movement" by speed.
	// interpolating the angle (not the vector) means a reversal swings the tail
	// around instead of collapsing it through zero.
	float spd = length(velocity);
	float move_w = smoothstep(trail_start_speed, trail_full_speed, spd);
	float up_angle = -PI * 0.5;
	float back_angle = spd > 0.001 ? atan(-velocity.y, -velocity.x) : up_angle;
	float angle_diff = mod(back_angle - up_angle + PI, TAU) - PI;
	float tail_angle = up_angle + angle_diff * move_w;
	vec2 tail_dir = vec2(cos(tail_angle), sin(tail_angle));
	float height = flame_height * (1.0 + move_w * max_stretch);

	// rotate into flame space, where the tail always points to -y
	vec2 right = vec2(-tail_dir.y, tail_dir.x);
	vec2 fp = vec2(dot(p, right), -dot(p, tail_dir));

	// 0 at the orb centre, 1 at the flame tip
	float up = clamp(-fp.y / height, 0.0, 1.0);

	// S-curl sway that grows toward the tip
	vec2 q = fp;
	q.x += sin(fp.y * curl_frequency + t * 2.0) * curl_amount * smoothstep(0.0, 1.0, up);

	// teardrop field: circle below the centre, tapering tongue above (<1 = inside)
	float y_up = max(-q.y, 0.0);
	float dyn_taper = taper + move_w * speed_taper;
	float w = body_radius * pow(max(1.0 - y_up / height, 0.0), dyn_taper);
	float field = q.y > 0.0 ? length(q) / body_radius : abs(q.x) / max(w, 0.001);

	// noise scrolls along the tail, breaking up the silhouette toward the tip
	float n = fbm(q * noise_scale + vec2(0.0, t));
	field += (n - 0.5) * noise_strength * (0.4 + up);
	field *= 1.0 + (value_noise(vec2(t * 3.0, 0.0)) - 0.5) * flicker;

	float intensity = (1.0 - field) * (1.0 - up * tail_cooling);

	// original orb drives the hot core (sampled unrotated)
	float orb_inside = step(max(abs(p.x), abs(p.y)), 1.0);
	vec4 orb = texture(TEXTURE, clamp(p * 0.5 + 0.5, 0.0, 1.0)) * orb_inside;
	float orb_luma = dot(orb.rgb, vec3(0.299, 0.587, 0.114)) * orb.a;
	intensity = max(intensity, orb_luma * orb_boost);

	// posterised colour bands
	vec4 col = vec4(0.0);
	if (intensity > 0.0) {
		col = edge_color;
		if (intensity > bands.x) col = outer_color;
		if (intensity > bands.y) col = mid_color;
		if (intensity > bands.z) col = core_color;
		col.rgb = mix(col.rgb, orb.rgb, orb.a * orb_color_mix);
	}

	// square embers shed along the tail direction
	if (col.a < 0.01) {
		vec2 ep = (p - tail_dir * t * ember_speed) * ember_density;
		vec2 cell = floor(ep);
		vec2 local = fract(ep);
		float h = hash21(cell);
		vec2 centre = vec2(hash21(cell + 17.1), hash21(cell + 31.7)) * 0.6 + 0.2;
		float half_ember = ember_size * ember_density * 0.5;
		float ember = step(1.0 - ember_chance, h);
		ember *= step(max(abs(local.x - centre.x), abs(local.y - centre.y)), half_ember);
		ember *= step(0.35, fract(h * 7.0 + t * 0.5)); // blink in and out
		float zone = step(1.15, field) * step(length(p - tail_dir * 0.6), ember_range);
		if (ember * zone > 0.5) {
			col = mid_color;
		}
	}

	COLOR = col * v_modulate;
}
