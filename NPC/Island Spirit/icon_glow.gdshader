shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
// Glow reach in texture pixels
uniform float glow_radius = 2.0;
uniform float glow_min : hint_range(0.0, 1.0) = 0.2;
uniform float glow_max : hint_range(0.0, 1.0) = 0.7;
// How much the icon itself brightens at the pulse peak
uniform float brighten : hint_range(0.0, 1.0) = 0.25;
uniform float pulse_speed = 3.0;

vec4 sample_sprite(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	return texture(tex, uv);
}

void fragment() {
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	vec4 col = sample_sprite(TEXTURE, UV);

	// Halo: average alpha of 8 surrounding samples, at two distances
	float halo = 0.0;
	for (int ring = 1; ring <= 2; ring++) {
		float dist = glow_radius * float(ring) * 0.5;
		for (int i = 0; i < 8; i++) {
			float angle = float(i) * TAU / 8.0;
			vec2 offset = vec2(cos(angle), sin(angle)) * dist * TEXTURE_PIXEL_SIZE;
			halo += sample_sprite(TEXTURE, UV + offset).a;
		}
	}
	halo /= 16.0;

	float glow_alpha = halo * mix(glow_min, glow_max, pulse);
	vec4 glow = vec4(glow_color.rgb, glow_alpha);

	col.rgb += col.rgb * brighten * pulse;

	// Icon on top, glow behind it
	vec4 result = mix(glow, col, col.a);
	result.a = max(col.a, glow_alpha);

	COLOR = result * COLOR;
}
