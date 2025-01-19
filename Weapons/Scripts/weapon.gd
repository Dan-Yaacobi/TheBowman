class_name Weapon extends Node2D

static var player: Player
@export var weapon_data: WeaponData

func shoot() -> void:
	var mouse_pos = player.get_global_mouse_position()
	# this long condition checks if the player clicks too close to the character
	# if it does, then an arrow will not fire
	# this fixes the issue when arrows fire in a wierd rotation
	if not (mouse_pos.x > player.global_position.x - 5 and mouse_pos.x < player.global_position.x + 5 and mouse_pos.y > player.global_position.y - 5 and mouse_pos.y < player.global_position.y + 5):
		var arrow = instance_arrow(weapon_data.arrow,global_position)
		arrow.direction = player.get_shoot_direction()
		arrow.rotate(set_arrow_rotation())
		player.get_parent().call_deferred("add_child",arrow)
		
func set_arrow_rotation() -> float:
	var player_pos = player.global_position
	var mouse_pos = player.get_global_mouse_position()
	var angle_rotation: float = (player_pos - mouse_pos).angle()
	return angle_rotation
	
func init_weapon(_player: Player, _weapon: Weapon) -> void:
	player = _player
	player.add_child(_weapon)
	pass

func instance_arrow(ARROW: PackedScene, the_position) -> Arrow:
	var arrow: Arrow = ARROW.instantiate()
	arrow.global_position = the_position
	arrow.z_index = -1
	return arrow
