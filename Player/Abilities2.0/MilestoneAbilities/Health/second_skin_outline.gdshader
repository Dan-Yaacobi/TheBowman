shader_type canvas_item;
// Second Skin outline. Draws a sprite as a flat-coloured silhouette.
// Positions are measured in world pixels relative to the player (origin).

uniform vec4 tint : source_color = vec4(1.0, 0.86, 0.45, 1.0);
uniform vec4 glint_color : source_color = vec4(1.0, 1.0, 0.92, 1.0);
uniform vec2 origin = vec2(0.0);
// Position of the glint along the diagonal (x - y). Far outside the body = no glint.
uniform float glint_pos = -1000.0;
uniform float glint_width = 1.5;
// Only rows at or below this y (relative to origin) are drawn. Used to fill in from the feet.
uniform float reveal_y = -1000.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float a = step(0.5, texture(TEXTURE, UV).a);
	vec2 rel = floor(world_pos - origin);
	float glint = step(abs((rel.x - rel.y) - glint_pos), glint_width);
	float shown = step(reveal_y, rel.y);
	COLOR = vec4(mix(tint.rgb, glint_color.rgb, glint), a * tint.a * shown);
}
