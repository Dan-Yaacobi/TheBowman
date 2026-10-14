shader_type canvas_item;

// Bob: whole sprite floats up and down, snapped to whole pixels
uniform float bob_amount = 2.0;
uniform float bob_speed = 2.0;

// Tail wave: horizontal sway that only affects the bottom of the sprite
uniform float tail_start : hint_range(0.0, 1.0) = 0.65;
uniform float tail_amount = 1.5;
uniform float tail_speed = 4.0;
uniform float tail_frequency = 12.0;

// Glow: brightens cyan pixels (eyes + wisp), pulses over time
uniform vec4 glow_color : source_color = vec4(0.4, 1.0, 1.0, 1.0);
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.25;
uniform float glow_strength = 0.5;
uniform float glow_speed = 2.0;

// 0 = idle, 1 = carrying schematics (eyes blaze). Tween this from code.
uniform float pending : hint_range(0.0, 1.0) = 0.0;

// 0 = normal, 1 = full white. Tween up and down for the build moment.
uniform float flash : hint_range(0.0, 1.0) = 0.0;

uniform bool pixel_snap = true;

void vertex() {
	float bob = sin(TIME * bob_speed) * bob_amount;
	if (pixel_snap) {
		bob = round(bob);
	}
	VERTEX.y += bob;
}

void fragment() {
	vec2 uv = UV;

	float tail_weight = smoothstep(tail_start, 1.0, uv.y);
	float wave = sin(TIME * tail_speed + uv.y * tail_frequency) * tail_amount * tail_weight;
	if (pixel_snap) {
		wave = round(wave);
	}
	uv.x += wave * TEXTURE_PIXEL_SIZE.x;

	vec4 col = texture(TEXTURE, uv) * COLOR;

	float cyan = min(col.g, col.b) - col.r;
	float mask = step(glow_threshold, cyan) * col.a;
	float pulse = 0.5 + 0.5 * sin(TIME * (glow_speed + pending * 4.0));
	float strength = glow_strength * (pulse + pending * 1.5);
	col.rgb += glow_color.rgb * mask * strength;

	col.rgb = mix(col.rgb, vec3(1.0), flash * col.a);

	COLOR = col;
}
