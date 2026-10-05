// Stepped pixel-art glow behind the crystal. ColorRect ~24x24 px centered on it.
shader_type canvas_item;
//render_mode blend_add;

uniform float activation : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.55, 0.75, 1.0, 0.8);
uniform float pulse_speed = 2.5;
uniform float bands = 4.0;
uniform vec2 pixel_res = vec2(24.0, 24.0);

void fragment() {
	vec2 uv = (floor(UV * pixel_res) + 0.5) / pixel_res;
	float r = length(uv * 2.0 - 1.0);
	float falloff = clamp(1.0 - r, 0.0, 1.0);
	falloff = floor(falloff * bands) / bands;
	float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
	COLOR = vec4(glow_color.rgb, falloff * falloff * pulse * activation * glow_color.a);
}
