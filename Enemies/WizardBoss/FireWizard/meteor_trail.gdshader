shader_type canvas_item;

// Draws a procedural fire trail behind a bare rock sprite.
// The shader grows the sprite's drawing area by margin_px so the flames have room outside the image,
// then draws the rock on top and a streaming comet-shaped fire behind it.
// Use on a Sprite2D showing a single image (no hframes/vframes or region).

group_uniforms Area;
// Extra drawing space around the image, in texture pixels: left, top, right, bottom
uniform vec4 margin_px = vec4(8.0, 44.0, 8.0, 6.0);

group_uniforms Shape;
// Direction the trail streams in, in sprite space (falling straight down = trail points up)
uniform vec2 trail_dir = vec2(0.0, -1.0);
// Offset of the fire's center from the image center, in pixels
uniform vec2 head_offset_px = vec2(0.0, 0.0);
// Radius of the fire around the rock, in pixels (a bit larger than the rock)
uniform float head_radius_px = 9.0;
// How far the trail reaches behind the rock, in pixels
uniform float trail_length_px = 38.0;
// Higher = trail narrows faster toward the tip
uniform float taper : hint_range(0.2, 3.0) = 1.2;
// Higher = flatter flame cap in front of the rock
uniform float front_squash : hint_range(0.5, 3.0) = 1.6;
// Heat left at the tail tip (lower = tip burns out into darker colors)
uniform float tail_heat : hint_range(0.0, 1.0) = 0.45;

group_uniforms Motion;
uniform float flow_speed = 4.0;
// Sideways whip at the tail tip, in pixels
uniform float wobble_px : hint_range(0.0, 8.0) = 2.5;
// Noise size across and along the trail; higher = smaller flame details
uniform float across_scale = 0.3;
uniform float along_scale = 0.15;
uniform float turbulence : hint_range(0.0, 2.0) = 0.8;
uniform float animation_fps = 12.0;
uniform bool pixel_snap = true;

group_uniforms Colors;
uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform vec4 inner_color : source_color = vec4(1.0, 0.7, 0.18, 1.0);
uniform vec4 outer_color : source_color = vec4(0.91, 0.31, 0.1, 1.0);
uniform vec4 edge_color : source_color = vec4(0.48, 0.1, 0.07, 1.0);
// Band thresholds, from the hot core outward
uniform float core_threshold : hint_range(0.0, 1.5) = 0.75;
uniform float inner_threshold : hint_range(0.0, 1.5) = 0.5;
uniform float outer_threshold : hint_range(0.0, 1.5) = 0.25;
uniform float edge_threshold : hint_range(0.0, 1.5) = 0.08;
group_uniforms;

varying vec4 modulate_color;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

void vertex() {
	modulate_color = COLOR;
	// Grow the quad outward so the fire can draw outside the original image
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 grow = vec2(mix(-margin_px.x, margin_px.z, UV.x), mix(-margin_px.y, margin_px.w, UV.y));
	VERTEX += grow;
	UV += grow / tex_size;
}

void fragment() {
	// The rock: drawn as-is wherever the original image has pixels
	bool inside = UV.x >= 0.0 && UV.x <= 1.0 && UV.y >= 0.0 && UV.y <= 1.0;
	vec4 rock = inside ? texture(TEXTURE, UV) : vec4(0.0);

	if (rock.a > 0.01) {
		COLOR = rock * modulate_color;
	} else {
		float t = floor(TIME * animation_fps) / animation_fps;
		vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
		vec2 px = UV * tex_size;
		if (pixel_snap) {
			px = floor(px) + 0.5;
		}

		vec2 dir = normalize(trail_dir);
		vec2 perp = vec2(-dir.y, dir.x);
		vec2 rel = px - (tex_size * 0.5 + head_offset_px);
		float along = dot(rel, dir);
		float across = dot(rel, perp);
		float tf = clamp(along / trail_length_px, 0.0, 1.0);

		// The tail whips sideways, more toward the tip
		float whip = noise(vec2(along * 0.12 - t * flow_speed * 0.4, 7.0)) - 0.5;
		across += whip * 2.0 * wobble_px * tf;

		// Flame detail streaming from the rock toward the tip
		float n1 = noise(vec2(across * across_scale, along * along_scale - t * flow_speed));
		float n2 = noise(vec2(across * across_scale * 2.0 + 13.0, along * along_scale * 2.0 - t * flow_speed * 1.5));
		float detail = n1 * 0.65 + n2 * 0.35;

		// Comet shape: a cap around the front of the rock, tapering trail behind it
		float shape;
		if (along < 0.0) {
			shape = 1.0 - length(vec2(across, along * front_squash)) / head_radius_px;
		} else {
			float width = head_radius_px * pow(max(1.0 - tf, 0.0), taper);
			shape = width > 0.001 ? 1.0 - abs(across) / width : -1.0;
			shape *= mix(1.0, tail_heat, tf);
		}

		float heat = shape + (detail - 0.5) * turbulence * mix(0.6, 1.4, tf);

		vec4 col = vec4(0.0);
		if (heat > core_threshold) {
			col = core_color;
		} else if (heat > inner_threshold) {
			col = inner_color;
		} else if (heat > outer_threshold) {
			col = outer_color;
		} else if (heat > edge_threshold) {
			col = edge_color;
		}

		COLOR = col * modulate_color;
	}
}
