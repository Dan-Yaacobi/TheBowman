class_name FlyingTarget extends Enemy

@onready var wings: AnimatedSprite2D = $Wings
@export var start_position: Vector2
@export var end_position: Vector2

var _heading_to_end: bool = true
var _moving: bool = false

func extra_ready_functions() -> void:
	wings.play("default")
	state_machine.Initialize(self)

## Places the target at `from` and starts flying back and forth to `to`. Global positions.
func set_route(from: Vector2, to: Vector2) -> void:
	start_position = from
	end_position = to
	global_position = from
	_heading_to_end = true
	_moving = true

func _physics_process(delta: float) -> void:
	if not _moving:
		return
	var speed: float = stats.move_speed.value()
	wings.speed_scale = speed / stats.move_speed.base_value
	var target_point: Vector2 = end_position if _heading_to_end else start_position
	var to_target: Vector2 = target_point - global_position
	if to_target.length() <= speed * delta:
		_heading_to_end = not _heading_to_end
		target_point = end_position if _heading_to_end else start_position
		to_target = target_point - global_position
	velocity = to_target.normalized() * speed
	move_and_slide()
