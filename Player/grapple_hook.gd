class_name GrappleHook extends Node2D

@onready var hook: Hook = $Hook
@export var throw_base_power: float = 150

func activate_hook() -> void:
	hook.active(true,
 	throw_base_power + PlayerManager.player.get_strength()*2,
	calculate_direction_to_cursor())
	
func calculate_direction_to_cursor() -> Vector2:
	var mouse_pos = PlayerManager.player.get_global_mouse_position()
	var player_pos = PlayerManager.player.global_position
	return Vector2(mouse_pos[0] - player_pos[0], mouse_pos[1] - player_pos[1]).normalized()
