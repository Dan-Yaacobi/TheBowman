shader_type canvas_item;
// Premultiplied alpha lets the glow brighten what's behind it, like real light.
render_mode blend_premul_alpha;

// 0 = off, 1 = full fireball. Tween this on dash start/end.
uniform float strength : hint_range(0.0, 1.0) = 1.0;

uniform vec4 ember_color : source_color = vec4(0.6, 0.06, 0.02, 1.0);
uniform vec4 flame_color : source_color = vec4(1.0, 0.42, 0.05, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.93, 0.6, 1.0);

// Direction of travel, set from script on dash start. Zero = round aura, no tail.
uniform vec2 direction = vec2(1.0, 0.0);
// Fireball size and tail length, as fractions of the sprite (1.0 = sprite edge).
uniform float radius : hint_range(0.05, 0.8) = 0.32;
uniform float tail_length : hint_range(0.0, 1.0) = 0.55;
// Flame detail: higher = smaller, busier tongues.
uniform float noise_scale : hint_range(1.0, 12.0) = 5.0;
// How ragged and licking the flame edge is.
uniform float noise_amount : hint_range(0.0, 1.0) = 0.55;
// How fast flames stream backward along the tail.
uniform float flow_speed : hint_range(0.0, 10.0) = 3.0;
// Soft glow around the flames.
uniform float glow_strength : hint_range(0.0, 2.0) = 0.6;
uniform float glow_falloff : hint_range(1.0, 20.0) = 7.0;

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

// Four smooth octaves, each rotated so the pattern never looks grid-aligned.
float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		v += value_noise(p) * amp;
		p = rot * p * 2.03 + 11.7;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float t = TIME;

	float dl = length(direction);
	vec2 d = dl > 0.001 ? direction / dl : vec2(1.0, 0.0);
	float tail = dl > 0.001 ? tail_length * strength : 0.0;
	float r = radius * strength;

	// Frame aligned with travel: x = distance behind the player, y = sideways.
	vec2 q = vec2(dot(p, -d), dot(p, vec2(-d.y, d.x)));

	// Warp the space with noise streaming backward, so flames curl and lick.
	vec2 flow = vec2(q.x - t * flow_speed * 0.25, q.y);
	vec2 warp = vec2(fbm(flow * noise_scale), fbm(flow * noise_scale + 5.2)) - 0.5;
	vec2 wq = q + warp * 0.12;

	// Heat: 1 at the center, 0 at the edge. Round in front...
	float h = 1.0 - length(wq) / max(r, 0.001);
	// ...and a tapering tail behind that cools toward its tip.
	if (wq.x > 0.0 && tail > 0.0) {
		float along = wq.x / tail;
		if (along < 1.0) {
			float w = r * pow(1.0 - along, 0.6);
			float ht = (1.0 - abs(wq.y) / max(w, 0.001)) * (1.0 - along);
			h = max(h, ht);
		}
	}

	// Flame tongues: more noise toward the edge, so the core stays solid.
	float n = fbm(vec2(q.x * noise_scale * 1.5 - t * flow_speed, q.y * noise_scale * 1.5));
	float heat = h + (n - 0.5) * noise_amount * (1.0 - clamp(h, 0.0, 1.0));

	// Color: deep red edges -> orange body -> pale yellow core.
	float body = smoothstep(0.0, 0.12, heat);
	float k = clamp(heat * 1.6, 0.0, 1.0);
	vec3 ramp = mix(ember_color.rgb, flame_color.rgb, smoothstep(0.0, 0.45, k));
	ramp = mix(ramp, core_color.rgb, smoothstep(0.5, 0.95, k));

	// Glow fades out smoothly beyond the flame's edge.
	float glow = exp(min(heat, 0.0) * glow_falloff) * glow_strength;

	vec3 col = ramp * body * 1.2 + flame_color.rgb * glow * (1.0 - body) * 0.6;
	float alpha = clamp(body + glow * 0.35 * (1.0 - body), 0.0, 1.0);

	// Fade before the sprite's edge so nothing shows a hard square cutoff.
	float edge_fade = 1.0 - smoothstep(0.85, 1.0, length(p));
	COLOR = vec4(col, alpha) * strength * edge_fade;
}
