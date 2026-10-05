// Swirling magical pool. Put on a ColorRect sized to the hole (e.g. 20x6 px);
// the rect's aspect ratio turns the circle into an ellipse automatically.
shader_type canvas_item;
render_mode blend_add;

uniform float activation : hint_range(0.0, 1.0) = 0.0;
uniform vec4 core_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.4, 0.25, 0.95, 1.0);
uniform float swirl_speed = 1.5;
uniform float swirl_twist = 6.0;
uniform float arms = 3.0;
uniform float posterize_steps = 4.0;
// Set to the rect's size in pixels so the effect snaps to the pixel grid.
uniform vec2 pixel_res = vec2(20.0, 6.0);

void fragment() {
	vec2 uv = (floor(UV * pixel_res) + 0.5) / pixel_res;
	vec2 p = uv * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float angle = atan(p.y, p.x);
	float swirl = sin(angle * arms + r * swirl_twist - TIME * swirl_speed) * 0.5 + 0.5;
	float bands = smoothstep(0.35, 0.9, swirl);
	float rim = smoothstep(0.55, 0.95, r) * 0.7;
	float center = 1.0 - smoothstep(0.0, 0.4, r);
	float intensity = clamp(bands * 0.55 + rim + center, 0.0, 1.0);
	intensity = floor(intensity * posterize_steps) / posterize_steps;
	vec3 col = mix(core_color.rgb, edge_color.rgb, r);
	COLOR = vec4(col, intensity * activation);
}
