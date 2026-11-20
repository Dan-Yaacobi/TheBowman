shader_type canvas_item;

// Scales pixel art by any (non-integer) factor without uneven pixels:
// every texel becomes a sharp square, with only a one-screen-pixel blend at its edges.
// Needs linear texture filtering on the node that draws it.

void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 texel = UV * tex_size;
	vec2 seam = floor(texel + 0.5);
	vec2 texels_per_pixel = fwidth(texel);
	texel = seam + clamp((texel - seam) / texels_per_pixel, -0.5, 0.5);
	COLOR = texture(TEXTURE, texel / tex_size);
}
