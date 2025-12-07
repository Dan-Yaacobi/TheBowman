class_name PlayerUpgrade extends Node2D

signal chosen

@export_category("Textures")
@export var texture: Texture
@export var color: Color


@export_category("Tooltip")
@export var tool_tip: String
@export var tool_tip2: String

@export_category("")
@export var ID: int
@export var bucket: int = 1
@export var is_ability: bool = false
@export var ability_chosen: bool = false
@export var can_choose_once: bool = false


func upgrade(_player: Player) -> void:
	pass

func upgrade2(_player: Player) -> void:
	pass
	
func get_current(_player: Player) -> String:
	return ""

func get_buff_tooltip(_player: Player) -> String:
	return ""
