shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

// Ray of light rising out of an opened chest, with a soft glow at its mouth.
// Draw it on a plain white texture: the texture only sets the canvas size
// (make it tall to make the beam reach higher).
// Premultiplied blending: alpha covers the background (so the gold stays gold
// over a bright sky) and `emission` adds light on top (so it glows).
// Fade it with the node's modulate alpha.

uniform vec4 beam_color : source_color = vec4(1.0, 0.68, 0.12, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.93, 0.55, 1.0);
// Overall opacity of the beam.
uniform float intensity : hint_range(0.0, 2.0) = 1.7;
// Extra additive light on top of the covered colour.
uniform float emission : hint_range(0.0, 2.0) = 0.6;

group_uniforms shape;
// UV height of the chest mouth; the beam starts here and rises to the top.
uniform float base_y : hint_range(0.0, 1.0) = 0.984;
// Half-width of the beam in texture pixels at the mouth and at the top.
uniform float base_half_width = 12.0;
uniform float top_half_width = 40.0;
// How fast the beam widens: >1 stays narrow longer, then flares near the top.
uniform float flare_curve : hint_range(0.2, 4.0) = 0.6;
// Higher = thinner bright core.
uniform float core_sharpness : hint_range(1.0, 12.0) = 3.0;
// Power on the fade toward the top: lower = reaches higher before fading.
uniform float top_fade : hint_range(0.2, 4.0) = 0.8;
// Pixels over which the beam fades in right at the mouth.
uniform float base_soft_px = 6.0;
// Opacity of the beam's outer edge relative to its core.
uniform float edge_opacity : hint_range(0.0, 1.0) = 0.8;

group_uniforms motion;
uniform float shimmer_speed : hint_range(0.0, 5.0) = 1.5;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.3;
// Distance between shimmer bands, in texture pixels.
uniform float shimmer_spacing = 36.0;
uniform float ray_count : hint_range(0.0, 30.0) = 9.0;
uniform float ray_strength : hint_range(0.0, 1.0) = 0.35;

group_uniforms glow;
// Glow ellipse radii in texture pixels, centred on the mouth.
uniform vec2 glow_radius = vec2(22.0, 10.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.9;
uniform float glow_pulse : hint_range(0.0, 1.0) = 0.15;

group_uniforms pixel_art;
// Snap to this many cells across the canvas (0 = off). Set to the on-screen pixel size.
uniform vec2 pixel_grid = vec2(36.0, 200.0);
// Opacity steps (0 = smooth).
uniform float alpha_steps : hint_range(0.0, 16.0) = 5.0;

void fragment() {
	vec2 uv = UV;
	if (pixel_grid.x > 0.0 && pixel_grid.y > 0.0) {
		uv = (floor(uv * pixel_grid) + 0.5) / pixel_grid;
	}
	float t = TIME * shimmer_speed;
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	// Position in texture pixels, origin at the mouth (y grows upward).
	vec2 p = vec2((uv.x - 0.5) * tex_size.x, (base_y - uv.y) * tex_size.y);

	// 0 at the mouth, 1 at the top of the canvas.
	float h = clamp((base_y - uv.y) / max(base_y, 0.001), 0.0, 1.0);
	float above = step(0.0, p.y);

	float half_w = mix(base_half_width, top_half_width, pow(h, flare_curve));
	float across = clamp(1.0 - abs(p.x) / max(half_w, 0.001), 0.0, 1.0);
	float beam = smoothstep(0.0, 0.6, across);
	float core = pow(across, core_sharpness);

	float vfade = smoothstep(0.0, base_soft_px, p.y) * pow(1.0 - h, top_fade);

	// Bands of light drifting upward.
	float wobble = sin(p.x * 0.13 + t) * 1.5;
	float shimmer = 1.0 - shimmer_strength * (0.5 + 0.5 * sin(-p.y * 6.2832 / shimmer_spacing + t * 6.0 + wobble));
	// Streaks fanning out from the mouth.
	float fan_x = p.x / max(half_w, 0.001);
	float rays = 1.0 - ray_strength * (0.5 + 0.5 * sin(fan_x * ray_count + sin(t * 0.7) * 1.5));

	float b = beam * vfade * shimmer * rays * above;
	float c = core * vfade * above;

	// Glow around the mouth (also spills a little below it).
	vec2 g = p / glow_radius;
	float glow = exp(-dot(g, g) * 2.0) * (1.0 + glow_pulse * sin(TIME * 3.0)) * glow_strength;

	// Gold at the edges, paler in the core and the glow.
	float whiteness = clamp(c * 0.5 + glow * 0.6, 0.0, 1.0);
	vec3 col = mix(beam_color.rgb, core_color.rgb, whiteness);
	float a = clamp(b * edge_opacity + c * (1.0 - edge_opacity) + glow, 0.0, 1.0) * intensity;
	if (alpha_steps > 0.0) {
		a = floor(a * alpha_steps + 0.5) / alpha_steps;
	}
	a = clamp(a, 0.0, 1.0);

	// Premultiplied: rgb = covered colour + added light, alpha = how much background is hidden.
	float fade = COLOR.a;
	vec3 rgb = col * a + col * a * emission;
	COLOR = vec4(rgb * fade, a * fade);
}
