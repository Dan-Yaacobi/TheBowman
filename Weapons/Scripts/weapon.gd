class_name Weapon extends Node2D

signal combo_loss
signal combo_gained
signal arrow_hit_sound
static var player: Player

@export var weapon_data: WeaponData

var base_damage: int = 0
var regular_attack: bool = true

func shoot() -> void:
	var mouse_pos = player.get_global_mouse_position()
	# this long condition checks if the player clicks too close to the character
	# if it does, then an arrow will not fire
	# this fixes the issue when arrows fire in a wierd rotation
	if not (mouse_pos.x > player.global_position.x - 5 and mouse_pos.x < player.global_position.x + 5 and mouse_pos.y > player.global_position.y - 5 and mouse_pos.y < player.global_position.y + 5):
		var arrow = instance_arrow(weapon_data.arrow,global_position)
		if weapon_data.can_pierce:
			arrow.can_pierce = true
		if weapon_data.arrows_explode:
			arrow.can_explode = true
		arrow.direction = player.get_shoot_direction()
		arrow.rotate(set_arrow_rotation())
		arrow.regular_shot = regular_attack
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
	if ARROW != null:
		var arrow: Arrow = ARROW.instantiate()
		arrow.arrow_hit_sound.connect(emit_hit_sound)
		if base_damage == 0:
			base_damage = arrow.data.damage
			
		if weapon_data.combo_buff_activated:
			arrow.data.damage = base_damage * 2
		else:
			arrow.data.damage = base_damage
		arrow.arrow_missed.connect(missed)
		arrow.arrow_hit.connect(hit)
		arrow.global_position = the_position
		arrow.z_index = -1
		return arrow
	return null

func emit_hit_sound() -> void:
	arrow_hit_sound.emit()

func missed() -> void:
	combo_loss.emit()
	pass

func hit() -> void:
	combo_gained.emit()
	pass
