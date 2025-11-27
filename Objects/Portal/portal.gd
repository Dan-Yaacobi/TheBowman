class_name Portal extends Node2D

@export var color: Color
@export var destination: String
@export var flip_h: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	sprite.flip_h = flip_h

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
