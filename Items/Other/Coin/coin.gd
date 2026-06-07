extends Sprite2D

@export var spin_speed: float = 1.0
@export var bob_height: float = 3.0
@export var bob_speed: float = 2.0
@export var edge_darken_color: Color = Color(0.5, 0.5, 0.5, 1.0)

var _base_y: float = 0.0
var _base_scale_x: float = 1.0
var _captured: bool = false

func _process(_delta: float) -> void:
	if not _captured:
		_base_y = position.y
		_base_scale_x = scale.x
		_captured = true

	var t: float = Time.get_ticks_msec() * 0.001

	position.y = _base_y + sin(t * bob_speed) * bob_height

	var s: float = abs(sin(t * spin_speed))
	var spin_x: float = pow(s, 0.35)

	scale.x = _base_scale_x * spin_x
	modulate = Color.WHITE.lerp(edge_darken_color, 1.0 - spin_x)
