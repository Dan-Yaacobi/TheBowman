class_name LeechAbility extends ShootAbility

func activate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.can_leech = true

func deactivate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.can_leech = false
	_player.stats.leech_chance = 10
