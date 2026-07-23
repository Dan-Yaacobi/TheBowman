class_name AfterimageSpawner extends Node2D

@export var active: bool = false
@export var min_interval: float = 0.02
@export var max_interval: float = 0.06
@export var min_alpha: float = 0.15
@export var max_alpha: float = 0.55
@export var lifetime: float = 0.12
@export var echo_color: Color = Color(1, 1, 1, 1)
@onready var target: ArrowSprite = $"../Sprite2D"

var velocity_factor: float = 1.0
var _timer: float = 0.0

func _process(delta: float) -> void:
	if not active or target == null:
		return
	var interval: float = lerpf(max_interval, min_interval, velocity_factor)
	_timer += delta
	if _timer >= interval:
		_timer = 0.0
		_spawn_echo()

func activate(_power: float) -> void:
	active = true
	velocity_factor = _power
func _spawn_echo() -> void:
	var echo: Sprite2D = Sprite2D.new()
	echo.texture = target.texture
	echo.global_position = target.global_position
	echo.global_rotation = target.global_rotation
	echo.global_scale = target.global_scale
	echo.flip_h = target.flip_h
	echo.flip_v = target.flip_v
	echo.hframes = target.hframes
	echo.vframes = target.vframes
	echo.frame = target.frame
	echo.modulate = echo_color
	echo.modulate.a = lerpf(min_alpha, max_alpha, velocity_factor)
	echo.z_index = target.z_index - 1
	get_tree().current_scene.add_child(echo)

	var tween: Tween = echo.create_tween()
	tween.tween_property(echo, "modulate:a", 0.0, lifetime)
	tween.tween_callback(echo.queue_free)
