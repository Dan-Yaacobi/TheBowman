shader_type canvas_item;

// Animates a still fireball sprite: the trail streams away from the hot head,
// snakes and whips around, tears apart toward the tip, the head pulses, and brightness flickers.
// The drawing area is grown by margin_px so flames can move past the image edges.
// Use on a Sprite2D showing a single image (no hframes/vframes or region).

group_uniforms Area;
// Extra drawing space around the image, in texture pixels: left, top, right, bottom.
// Give the sides the trail swings toward enough room for wave_px + wobble_px.
uniform vec4 margin_px = vec4(8.0, 8.0, 3.0, 8.0);

group_uniforms Shape;
// Where the hot head of the fireball sits in the image, in UV (0-1)
uniform vec2 head_uv = vec2(0.72, 0.55);
// Direction the trail points in the image, from the head toward the tail tip
uniform vec2 flow_dir = vec2(-1.0, -0.15);
// Length of the trail from the head to the tip, in pixels
uniform float trail_length_px = 28.0;

group_uniforms Wave;
// Big snaking motion: a wave that travels down the trail, swinging the whole tail
uniform float wave_px : hint_range(0.0, 10.0) = 3.5;
// How many bends fit along the trail (higher = tighter S-curves)
uniform float wave_frequency : hint_range(0.0, 1.0) = 0.22;
uniform float wave_speed = 9.0;
// How much the swing grows toward the tip (higher = head stays steadier)
uniform float wave_tip_bias : hint_range(0.5, 3.0) = 1.4;

group_uniforms Motion;
uniform float flow_speed = 5.0;
// Small chaotic flutter on top of the wave, in pixels (grows toward the tip)
uniform float wobble_px : hint_range(0.0, 8.0) = 2.5;
// Noise size across and along the trail; higher = smaller flame details
uniform float across_scale = 0.35;
uniform float along_scale = 0.2;
uniform float animation_fps = 12.0;
uniform bool pixel_snap = true;

group_uniforms Pulse;
// How much the head swells and shrinks (0 = no pulse)
uniform float pulse_amount : hint_range(0.0, 0.3) = 0.1;
uniform float pulse_speed = 9.0;

group_uniforms Look;
// How much the trail tears apart toward the tip (0 = solid)
uniform float tail_breakup : hint_range(0.0, 1.0) = 0.55;
uniform float flicker : hint_range(0.0, 1.0) = 0.25;
// How much darker the tail tip gets compared with the head
uniform float tail_darken : hint_range(0.0, 1.0) = 0.25;
group_uniforms;

varying vec4 modulate_color;

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

vec4 sample_image(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	return texture(tex, uv);
}

void vertex() {
	modulate_color = COLOR;
	// Grow the quad outward so the flames can draw outside the original image
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 grow = vec2(mix(-margin_px.x, margin_px.z, UV.x), mix(-margin_px.y, margin_px.w, UV.y));
	VERTEX += grow;
	UV += grow / tex_size;
}

void fragment() {
	float t = floor(TIME * animation_fps) / animation_fps;
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 px = UV * tex_size;
	if (pixel_snap) {
		px = floor(px) + 0.5;
	}

	vec2 dir = normalize(flow_dir);
	vec2 across_dir = vec2(-dir.y, dir.x);
	vec2 head_px = head_uv * tex_size;
	vec2 rel = px - head_px;
	float along = dot(rel, dir);
	float across = dot(rel, across_dir);

	// 0 at the head, 1 at the tail tip
	float tf = clamp(along / trail_length_px, 0.0, 1.0);
	float tip_weight = pow(tf, 1.0 / wave_tip_bias);

	// Snaking wave traveling from head to tip, with a slow second wave so it never repeats exactly
	float wave = sin(along * wave_frequency - t * wave_speed);
	wave += 0.5 * sin(along * wave_frequency * 0.47 - t * wave_speed * 0.63 + 1.7);
	wave /= 1.5;

	// Noise streaming from the head toward the tip
	float n_wave = noise(vec2(across * across_scale, along * along_scale - t * flow_speed));
	float n_flutter = noise(vec2(across * across_scale * 2.3 + 7.0, along * along_scale * 2.1 - t * flow_speed * 1.8));
	float n_break = noise(vec2(across * across_scale * 1.7 + 31.0, along * along_scale * 1.3 - t * flow_speed * 1.4));

	// Swing (wave) + flutter (noise), both stronger toward the tip; pull from upstream so shapes travel backward
	float side = wave * wave_px * tip_weight;
	side += ((n_wave - 0.5) * 1.4 + (n_flutter - 0.5) * 0.6) * 2.0 * wobble_px * tf;
	float back = n_break * wobble_px * 0.6 * tf;
	vec2 offset_px = across_dir * side - dir * back;

	// Head pulse: scale the image around the head, fading out along the trail
	float pulse = 1.0 + sin(t * pulse_speed) * pulse_amount * (1.0 - tf);
	vec2 sample_px = head_px + rel / pulse + offset_px;
	if (pixel_snap) {
		sample_px = floor(sample_px) + 0.5;
	}

	vec4 col = sample_image(TEXTURE, sample_px / tex_size);

	if (col.a > 0.01) {
		// Tear the trail apart toward the tip
		if (n_break < tf * tail_breakup) {
			col = vec4(0.0);
		} else {
			float light = mix(1.0 - flicker, 1.0 + flicker, n_wave);
			light *= mix(1.0, 1.0 - tail_darken, tf);
			col.rgb = clamp(col.rgb * light, 0.0, 1.0);
		}
	}

	COLOR = col * modulate_color;
}
