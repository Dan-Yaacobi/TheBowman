class_name EventPortal extends Node2D

## Leave empty to make this an exit portal (used inside event scenes).
@export var event_scene: PackedScene
@export var one_shot: bool = true
@export var vanish_duration: float = 1.0
@export var float_height: float = 4.0
@export var float_duration: float = 1.5

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var can_enter: bool = false
var is_used: bool = false

func _ready() -> void:
	animated_sprite_2d.play("default")
	_start_floating()

func _start_floating() -> void:
	var base_y: float = animated_sprite_2d.position.y
	var tween: Tween = animated_sprite_2d.create_tween().set_loops()
	tween.tween_property(animated_sprite_2d, "position:y", base_y - float_height, float_duration * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(animated_sprite_2d, "position:y", base_y + float_height, float_duration * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("up") and can_enter and not is_used:
		get_viewport().set_input_as_handled()
		teleport_player()

func teleport_player() -> void:
	if event_scene:
		if one_shot:
			is_used = true
			EventBus.event_exited.connect(_vanish, CONNECT_ONE_SHOT)
		EventBus.event_enter_requested.emit(event_scene, global_position)
	else:
		EventBus.event_exit_requested.emit()

func _vanish() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, vanish_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		can_enter = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		can_enter = false
