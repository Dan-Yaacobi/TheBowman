class_name BlueBow extends Weapon

#func shoot() -> void:
	#var mouse_pos = player.get_global_mouse_position()
	## this long condition checks if the player clicks too close to the character
	## if it does, then an arrow will not fire
	## this fixes the issue when arrows fire in a wierd rotation
	#if not (mouse_pos.x > player.global_position.x - 5 and mouse_pos.x < player.global_position.x + 5 and mouse_pos.y > player.global_position.y - 5 and mouse_pos.y < player.global_position.y + 5):
		#var arrow = instance_arrow(weapon_data.arrow,1,global_position)
		#arrow.direction = player.get_shoot_direction()
		#arrow.rotate(set_arrow_rotation())
		#player.get_parent().call_deferred("add_child",arrow)
