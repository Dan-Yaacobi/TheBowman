class_name ChargeMegaAbility extends ShootAbility

func activate_ability(_player: Player) -> void:
	_player.stats.can_mega_shot = true

func deactivate_ability(_player: Player) -> void:
	_player.stats.can_mega_shot = false
