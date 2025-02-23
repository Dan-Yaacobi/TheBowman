class_name CritAbility extends ShootAbility

func activate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.crit_arrows = true

func deactivate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.crit_arrows = false
	_player.stats.crit_chance = 10
