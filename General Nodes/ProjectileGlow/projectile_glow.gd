class_name ProjectileGlow extends Sprite2D
## Soft additive halo behind an enemy projectile, so it reads against busy backgrounds.
## Stepped rings (no smooth gradient) to stay in the pixel style. Pulses gently.
## Use ProjectileGlow.attach(projectile) from the projectile's _ready().

const TEXTURE_SIZE: int = 16
const FALLBACK_COLOR: Color = Color(1.0, 0.75, 0.45)

## Halo diameter as a multiple of the projectile's visible art.
@export var size_mult: float = 2.0
@export var pulse_speed: float = 7.0
## How far the pulse dims the halo (0 = no pulse).
@export var pulse_depth: float = 0.3
@export var glow_color: Color = FALLBACK_COLOR

static var _halo_texture: Texture2D
## Per texture path: [glow color, visible size in pixels].
static var _art_cache: Dictionary[String, Array] = {}

var _time: float = 0.0

## Adds a halo behind target's first Sprite2D. Pass a color to override the one read from the sprite.
static func attach(target: Node2D, color: Color = Color.TRANSPARENT) -> ProjectileGlow:
	var source: Sprite2D = _find_sprite(target)
	var art: Array = _read_art(source)
	var glow: ProjectileGlow = ProjectileGlow.new()
	glow.name = "ProjectileGlow"
	glow.glow_color = color if color.a > 0.0 else art[0]
	glow.texture = _get_halo_texture()
	var diameter: float = art[1] * (absf(source.scale.x) if source else 1.0)
	glow.scale = Vector2.ONE * maxf(diameter * glow.size_mult, 8.0) / TEXTURE_SIZE
	glow.position = source.position if source else Vector2.ZERO
	target.add_child(glow)
	# First child, so it draws behind the projectile's sprite.
	target.move_child(glow, 0)
	return glow

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	_time = randf() * TAU
	modulate = glow_color

func _process(delta: float) -> void:
	_time += delta * pulse_speed
	var strength: float = 1.0 - pulse_depth * (0.5 + 0.5 * sin(_time))
	modulate = Color(glow_color, glow_color.a * strength)

static func _find_sprite(target: Node2D) -> Sprite2D:
	for child: Node in target.get_children():
		if child is Sprite2D and not child is ProjectileGlow and (child as Sprite2D).texture:
			return child
	return null

## A bright version of the art's average color, and the size of one frame's visible art.
static func _read_art(source: Sprite2D) -> Array:
	if source == null or source.texture == null:
		return [FALLBACK_COLOR, 12.0]
	var key: String = source.texture.resource_path if source.texture.resource_path != "" else str(source.texture.get_rid())
	key += "/%dx%d" % [source.hframes, source.vframes]
	if _art_cache.has(key):
		return _art_cache[key]
	var image: Image = source.texture.get_image()
	if image == null:
		return [FALLBACK_COLOR, 12.0]
	if image.is_compressed():
		image.decompress()
	var total: Color = Color(0, 0, 0, 0)
	var count: int = 0
	for y: int in range(0, image.get_height(), 2):
		for x: int in range(0, image.get_width(), 2):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.5:
				total += pixel
				count += 1
	var color: Color = FALLBACK_COLOR
	if count > 0:
		var average: Color = total / count
		color = Color.from_hsv(average.h, clampf(average.s, 0.35, 0.85), 1.0)
	var size: float
	if source.hframes * source.vframes > 1:
		var frame: Vector2 = Vector2(image.get_width() / float(source.hframes), image.get_height() / float(source.vframes))
		size = maxf(frame.x, frame.y) * 0.7
	else:
		var used: Rect2i = image.get_used_rect()
		size = float(maxi(used.size.x, used.size.y))
	var result: Array = [color, size]
	_art_cache[key] = result
	return result

## White stepped rings fading outward; tinted by modulate.
static func _get_halo_texture() -> Texture2D:
	if _halo_texture:
		return _halo_texture
	var gradient: Gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 0.72, 0.95])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.32), Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.0)])
	var halo: GradientTexture2D = GradientTexture2D.new()
	halo.gradient = gradient
	halo.fill = GradientTexture2D.FILL_RADIAL
	halo.fill_from = Vector2(0.5, 0.5)
	halo.fill_to = Vector2(1.0, 0.5)
	halo.width = TEXTURE_SIZE
	halo.height = TEXTURE_SIZE
	_halo_texture = halo
	return _halo_texture
