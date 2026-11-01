class_name MagicEssence extends Item

@export var turn_smoothing: float = 8.0
@export var speed_smoothing: float = 10.0
@export var min_turn_speed: float = 5.0


var _last_position: Vector2 = Vector2.ZERO
var _has_last_position: bool = false
var _move_angle: float = -PI / 2.0
var _move_speed: float = 0.0

func extra_ready_functions() -> void:
	return

func launch(_target: Vector2) -> void:
	_landed = false
	var origin: Vector2 = global_position
	var scatter_x: float = randf_range(-21.0, 21.0)
	var destination: Vector2 = origin + Vector2(scatter_x, 0.0)
	_tween = create_tween()
	var mid: Vector2 = (origin + destination) / 2.0 + Vector2(0, -arc_height)
	_tween.tween_method(_move_along_arc.bind(origin, mid, destination), 0.0, 1.0, arc_duration)
	_tween.tween_callback(_on_arc_complete)
