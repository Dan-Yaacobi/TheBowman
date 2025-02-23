class_name StunAbility extends ShootAbility


func activate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.can_stun = true

func deactivate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.can_stun = false
	_player.stats.stun_chance = 10
