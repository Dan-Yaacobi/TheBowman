class_name Hook extends Area2D

@onready var hook_string: Line2D = $"../HookString"
@onready var line_point: Node2D = $LinePoint
@onready var grapple_hook: GrappleHook = $".."

@export var max_length: float = 125
var is_active: bool = false
var power: float = 0
var grapple_direction: Vector2
var retreating: bool = false

func _ready() -> void:
	disable()
	
func _process(delta: float) -> void:
	if retreating:
		global_position -= 5 * delta * (hook_string.points[1] - hook_string.points[0])
		monitoring = false
		if rope_length() < 15:
			retreating = false
			disable()
	else:
		if is_active:
			if rope_length() > max_length:
				retreating = true
			global_position += delta * (power) * grapple_direction
			rotation = hook_string.points[0].angle_to(hook_string.points[1]) - PI/4
	hook_string.points[1] = hook_string.to_local(line_point.global_position)

func active(_active: bool, _power: float = 0, _direction: Vector2 = Vector2.ZERO) -> void:
	is_active = _active
	visible = _active
	monitorable = _active
	monitoring = _active
	power = _power
	grapple_direction = _direction
	hook_string.visible = _active
	var new_hook_pos = PlayerManager.player.global_position + _direction * 5
	global_position = new_hook_pos
	hook_string.points[1] = hook_string.to_local(new_hook_pos)
	hook_string.points[0] = hook_string.to_local(PlayerManager.player.global_position)

func disable() -> void:
	active(false)
	call_deferred("reparent", grapple_hook)

func rope_length() -> float:
	return hook_string.points[0].distance_to(hook_string.points[1])

func reached_hook() -> bool:
	if rope_length() < 20:
		return true
	return false

func retreat() -> void:
	
	pass
