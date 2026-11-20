shader_type canvas_item;
// Soft halo behind the enemy health bar so it reads over status effects (burn flames etc).
// rect_size must match the Glow ColorRect's size; the bar sits glow_size in from each edge.

uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.8, 0.55);
uniform vec2 rect_size = vec2(88.0, 34.0);
uniform float glow_size = 12.0;

void fragment() {
	vec2 p = UV * rect_size;
	vec2 inner_min = vec2(glow_size);
	vec2 inner_max = rect_size - vec2(glow_size);
	vec2 d = max(max(inner_min - p, p - inner_max), vec2(0.0));
	float falloff = 1.0 - smoothstep(0.0, glow_size, length(d));
	COLOR = vec4(glow_color.rgb, glow_color.a * falloff * falloff);
}
