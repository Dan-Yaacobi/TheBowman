class_name ThunderBowAbility extends SpecialAbility

const THUNDER_STRIKE = preload("res://Player/Abilities/SpecialAbilities/ThunderBowAbility/ThunderStrike.tscn")

func activate_special_ability(_player: Player) -> void:
	var thunder_strike = THUNDER_STRIKE.instantiate()
	thunder_strike.global_position = _player.global_position
	_player.get_parent().call_deferred("add_child",thunder_strike)
	thunder_strike.emitting = true
	
	pass
