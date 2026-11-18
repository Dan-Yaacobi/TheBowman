shader_type canvas_item;

// Pulsing outline in the item's color type, plus a soft rim tint on the sprite itself.
uniform vec4 glow_color : source_color = vec4(0.55, 0.75, 0.95, 1.0);
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;
uniform float shine_speed : hint_range(0.0, 5.0) = 0.6;

// Vertex color (modulate) on its own: fragment COLOR already has the texture in it,
// which would zero the outline where the texture is transparent.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
	float neighbours = 0.0;
	neighbours += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	neighbours += texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	neighbours += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	neighbours += texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	neighbours += texture(TEXTURE, UV + px).a;
	neighbours += texture(TEXTURE, UV - px).a;
	neighbours += texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
	neighbours += texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
	float pulse = 0.65 + 0.35 * sin(TIME * pulse_speed);
	float edge = clamp(neighbours, 0.0, 1.0) * (1.0 - tex.a);

	// A diagonal shine band sweeping across the sprite every few seconds.
	float band = fract((UV.x + UV.y) * 0.5 - TIME * shine_speed);
	float shine = smoothstep(0.08, 0.0, abs(band - 0.5)) * tex.a;

	vec3 body = mix(tex.rgb, glow_color.rgb, rim_strength * pulse * tex.a);
	body += vec3(shine * 0.6);
	vec4 outline = vec4(glow_color.rgb * (1.0 + 0.4 * pulse), edge * pulse);
	vec4 result = mix(outline, vec4(body, tex.a), tex.a);
	COLOR = result * tint;
}
