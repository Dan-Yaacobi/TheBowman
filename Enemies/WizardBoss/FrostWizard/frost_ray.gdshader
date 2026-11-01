shader_type canvas_item;

// 0 = barely there, 1 = full beam. Drives the width.
uniform float power : hint_range(0.0, 1.0) = 1.0;
// While charging the beam is a flickering aim line
uniform bool charging = false;
// Overall fade (used when the beam shuts off)
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
// Size of the ColorRect in pixels: one cell per screen pixel
uniform vec2 rect_size = vec2(700.0, 12.0);
uniform float min_width = 1.0;
uniform float max_width = 10.0;
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 inner_color : source_color = vec4(0.66, 0.93, 1.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.32, 0.64, 0.95, 1.0);
uniform vec4 edge_color : source_color = vec4(0.12, 0.22, 0.48, 1.0);
// Pixels per second the frost texture streams away from the caster
uniform float flow_speed = 90.0;
// Edge ripple in pixels at full power
uniform float wobble = 1.5;
uniform float animation_fps = 12.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 px = floor(UV * rect_size);
	float t = floor(TIME * animation_fps) / animation_fps;
	float along = px.x;
	float across = abs(px.y + 0.5 - rect_size.y * 0.5);

	float width = mix(min_width, max_width, power);
	float ripple = hash(vec2(floor((along - t * flow_speed) / 3.0), 0.0)) - 0.5;
	float half_width = max(width * 0.5 + ripple * wobble * power, 0.5);
	// Rounded start at the caster's hand
	half_width = min(half_width, along * 0.6 + 0.5);
	if (across > half_width) {
		discard;
	}

	float d = across / half_width;
	vec4 col = edge_color;
	if (d < 0.3) {
		col = core_color;
	} else if (d < 0.6) {
		col = inner_color;
	} else if (d < 0.85) {
		col = outer_color;
	}

	// Frost glints streaming down the beam
	float glint = hash(vec2(floor((along - t * flow_speed) / 2.0), px.y));
	if (glint > 0.96 && d < 0.85) {
		col = core_color;
	}

	if (charging) {
		float flicker = hash(vec2(floor(TIME * 20.0), 3.0));
		col.a *= 0.45 + 0.55 * flicker;
	}
	col.a *= opacity;
	COLOR = col;
}
