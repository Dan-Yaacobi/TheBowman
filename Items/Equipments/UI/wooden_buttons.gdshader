shader_type canvas_item;

uniform float transparency: hint_range(0.0, 1.0) = 0.9;
uniform vec4 wood_light: source_color = vec4(0.55, 0.35, 0.15, 1.0);
uniform vec4 wood_dark: source_color = vec4(0.25, 0.13, 0.05, 1.0);
uniform vec4 hover_tint: source_color = vec4(0.8, 0.6, 0.3, 1.0);
uniform vec4 border_color: source_color = vec4(0.12, 0.06, 0.02, 1.0);
uniform float grain_scale: hint_range(1.0, 20.0) = 8.0;
uniform float grain_distortion: hint_range(0.0, 1.0) = 0.25;
uniform float border_width: hint_range(0.0, 0.2) = 0.06;
uniform bool hovered = false;
uniform bool pressed = false;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	float distort = noise(UV * grain_scale) * grain_distortion;
	float grain = sin((UV.y + distort) * grain_scale * 12.0) * 0.5 + 0.5;
	float fine = noise(UV * grain_scale * 4.0) * 0.25;
	grain = clamp(grain + fine, 0.0, 1.0);

	vec4 wood = mix(wood_dark, wood_light, grain);

	if (hovered) wood = mix(wood, hover_tint, 0.25);
	if (pressed) wood = mix(wood, wood_dark, 0.35);

	float bx = step(border_width, UV.x) * step(UV.x, 1.0 - border_width);
	float by = step(border_width, UV.y) * step(UV.y, 1.0 - border_width);
	wood = mix(border_color, wood, bx * by);

	wood.a *= transparency;
	COLOR = wood;
}