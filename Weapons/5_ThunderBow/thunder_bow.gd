class_name ThunderBow extends Weapon

func shoot() -> void:
	var mouse_pos = player.get_global_mouse_position()
	# this long condition checks if the player clicks too close to the character
	# if it does, then an arrow will not fire
	# this fixes the issue when arrows fire in a wierd rotation
	if not (mouse_pos.x > player.global_position.x - 5 and mouse_pos.x < player.global_position.x + 5 and mouse_pos.y > player.global_position.y - 5 and mouse_pos.y < player.global_position.y + 5):
		var arrow = instance_arrow(weapon_data.arrow,global_position)
		var arrow2 = instance_arrow(weapon_data.arrow,global_position)
		arrow.direction = player.get_shoot_direction()
		var offset: Vector2 = Vector2(randf_range(-0.2,0.2),randf_range(-0.2,0.2))
		arrow2.direction = player.get_shoot_direction() + offset
		arrow2.regular_shot = false
		arrow.rotate(set_arrow_rotation())
		arrow2.rotate(set_arrow_rotation())
		player.get_parent().call_deferred("add_child",arrow)
		player.get_parent().call_deferred("add_child",arrow2)
