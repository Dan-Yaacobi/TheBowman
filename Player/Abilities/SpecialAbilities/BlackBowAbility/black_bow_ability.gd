class_name BlackBowAbility extends SpecialAbility

var player: Player
var total_arrows_shot: int = 36

func activate_special_ability(_player: Player) -> void:
	player = _player
	var the_arrow: PackedScene = player.current_weapon.weapon_data.arrow
	for i in total_arrows_shot:
		var arrow: Arrow = instance_special_arrow(the_arrow,player.global_position,get_angle(i),get_direction(i))
		player.get_parent().call_deferred("add_child",arrow)
	pass

func get_direction(_arrow_number: int) -> Vector2:
	return Vector2(cos(get_angle(_arrow_number)),sin(get_angle(_arrow_number)))
	
func get_angle(_arrow_number: int) -> int:
	return _arrow_number*(360/total_arrows_shot)

func instance_special_arrow(ARROW: PackedScene, _the_position,_rotation_angle,_direction) -> Arrow:
	var arrow: Arrow = ARROW.instantiate()
	arrow.global_position = _the_position
	arrow.z_index = -1
	arrow.rotate(_rotation_angle)
	arrow.direction = _direction
	return arrow
