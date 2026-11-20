class_name MenuTower extends Sprite2D
## The final tower on the horizon, the one landmark that should pull the eye:
## a violet halo breathes behind it and the star on its tip twinkles.

## The star's centre in local (centered) pixels.
@export var star_offset: Vector2 = Vector2(-1.5, -33.5)
@export var star_color: Color = Color(1.0, 0.85, 1.0)
## Twinkle ray length range, in pixels.
@export var ray_length: Vector2i = Vector2i(2, 6)
@export var twinkle_speed: float = 2.4
@export var halo_alpha: Vector2 = Vector2(0.45, 0.85)
@export var breathe_speed: float = 1.1

@onready var halo: Sprite2D = $Halo

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	halo.modulate.a = lerpf(halo_alpha.x, halo_alpha.y, sin(_time * breathe_speed) * 0.5 + 0.5)
	queue_redraw()

## Pixel rays out of the star, longest straight up/down/sideways, fading toward their tips.
func _draw() -> void:
	var twinkle: float = sin(_time * twinkle_speed) * 0.5 + 0.5
	var length: int = roundi(lerpf(ray_length.x, ray_length.y, twinkle))
	var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for direction: Vector2 in directions:
		for i: int in range(2, length + 1):
			var color: Color = Color(star_color, 1.0 - float(i - 1) / (length + 1))
			draw_rect(Rect2(star_offset + direction * i - Vector2(0.5, 0.5), Vector2.ONE), color)
	if length > ray_length.x + 1:
		var diagonals: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
		for diagonal: Vector2 in diagonals:
			draw_rect(Rect2(star_offset + diagonal - Vector2(0.5, 0.5), Vector2.ONE), Color(star_color, 0.6))
