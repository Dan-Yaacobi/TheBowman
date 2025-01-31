class_name PlayerUpgrade extends Node2D

signal chosen

@export_category("Textures")
@export var normal_texture: Texture
@export var pressed_texture: Texture
@export var hover_texture: Texture
@export var color: Color


@export_category("Tooltip")
@export var tool_tip: String

@export var bucket: int = 1
@export var is_ability: bool = false
func upgrade(_player: Player) -> void:
	if _player != null:
		print("Upgraded")

func get_current(_player: Player) -> String:
	return ""
