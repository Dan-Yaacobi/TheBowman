@tool
class_name Portal extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		if Engine.is_editor_hint():
			call_deferred("_update_color")
		else:
			_update_color()

@export var destination: String

@export var flip_h: bool = false:
	set(value):
		flip_h = value
		if Engine.is_editor_hint():
			call_deferred("_update_flip")
		else:
			_update_flip()

func _ready() -> void:
	_update_flip()
	_update_color()

func disable() -> void:
	area_2d.monitoring = false

func enable() -> void:
	area_2d.monitoring = true
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.current_portal = self

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		body.current_portal = null

func enter() -> void:
	if destination != "":
		EventBus.changed_scene.emit(destination)

func _update_flip() -> void:
	if sprite:
		sprite.flip_h = flip_h

func _update_color() -> void:
	if sprite:
		sprite.modulate = color
	
