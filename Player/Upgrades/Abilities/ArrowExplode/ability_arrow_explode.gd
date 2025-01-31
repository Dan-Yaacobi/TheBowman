class_name ArrowExplodeAbility extends ShootAbility

func activate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.arrows_explode = true

func deactivate_ability(_player: Player) -> void:
	_player.current_weapon.weapon_data.arrows_explode = false
