class_name PlayerPierceUpgrade extends ShootAbility

func activate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.can_pierce = true

func deactivate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.can_pierce = false
