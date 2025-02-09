class_name StunAbility extends ShootAbility


func activate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.can_stun = true
	pass
	
func deactivate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.can_stun = false
	pass
