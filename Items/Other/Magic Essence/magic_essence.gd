class_name MagicEssence extends Item

@export var turn_smoothing: float = 8.0
@export var speed_smoothing: float = 10.0
@export var min_turn_speed: float = 5.0

@onready var flame_sprite: Sprite2D = $Sprite2D

var _flame_material: ShaderMaterial = null
var _last_position: Vector2 = Vector2.ZERO
var _has_last_position: bool = false
var _move_angle: float = -PI / 2.0
var _move_speed: float = 0.0

func extra_ready_functions() -> void:
	_flame_material = flame_sprite.material.duplicate() as ShaderMaterial
	flame_sprite.material = _flame_material

func launch(_target: Vector2) -> void:
	_landed = false
	var origin: Vector2 = global_position
	var scatter_x: float = randf_range(-21.0, 21.0)
	var destination: Vector2 = origin + Vector2(scatter_x, 0.0)
	_tween = create_tween()
	var mid: Vector2 = (origin + destination) / 2.0 + Vector2(0, -arc_height)
	_tween.tween_method(_move_along_arc.bind(origin, mid, destination), 0.0, 1.0, arc_duration)
	_tween.tween_callback(_on_arc_complete)

func extra_process_functions(delta: float) -> void:
	if _landed:
		_update_flame_velocity(delta)

func _update_flame_velocity(delta: float) -> void:
	if delta <= 0.0 or _flame_material == null:
		return
	if not _has_last_position:
		_last_position = global_position
		_has_last_position = true
		return
	var raw_velocity: Vector2 = (global_position - _last_position) / delta
	_last_position = global_position
	var raw_speed: float = raw_velocity.length()

	_move_speed = lerpf(_move_speed, raw_speed, 1.0 - exp(-speed_smoothing * delta))
	# only turn while actually moving, so the direction doesn't jitter at rest
	if raw_speed > min_turn_speed:
		_move_angle = lerp_angle(_move_angle, raw_velocity.angle(), 1.0 - exp(-turn_smoothing * delta))

	var smoothed_velocity: Vector2 = Vector2.from_angle(_move_angle) * _move_speed
	_flame_material.set_shader_parameter("velocity", smoothed_velocity)
