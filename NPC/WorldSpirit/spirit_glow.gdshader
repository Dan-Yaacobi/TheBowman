shader_type canvas_item;
// Pulsing outline glow for the world spirit while schematics wait to be revealed.
// glow_strength is driven from world_spirit.gd (0 = off, 1 = full).

uniform float glow_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.45, 0.95, 1.0, 1.0);
// Outline thickness in texture pixels.
uniform int glow_radius : hint_range(1, 6) = 3;
// Pulses per second times 2*PI.
uniform float pulse_speed = 3.0;
// How much the head itself tints toward glow_color at the pulse peak.
uniform float inner_tint : hint_range(0.0, 1.0) = 0.2;

const int DIRECTIONS = 16;

void fragment() {
	// COLOR already holds texture * modulate.
	vec4 base = COLOR;
	float pulse = 0.65 + 0.35 * sin(TIME * pulse_speed);

	float outline = 0.0;
	if (glow_strength > 0.0 && base.a < 1.0) {
		for (int i = 0; i < DIRECTIONS; i++) {
			float angle = float(i) * 6.2831853 / float(DIRECTIONS);
			vec2 dir = vec2(cos(angle), sin(angle));
			for (int r = 1; r <= glow_radius; r++) {
				float a = texture(TEXTURE, UV + dir * float(r) * TEXTURE_PIXEL_SIZE).a;
				// Closer pixels glow brighter.
				float falloff = 1.0 - float(r - 1) / float(glow_radius);
				outline = max(outline, a * falloff);
			}
		}
	}

	float glow = outline * glow_strength * pulse * (1.0 - base.a);
	vec3 head = mix(base.rgb, glow_color.rgb, inner_tint * glow_strength * pulse);
	COLOR.rgb = mix(glow_color.rgb, head, base.a);
	COLOR.a = max(base.a, glow * glow_color.a);
}
