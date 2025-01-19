class_name RedBowAbility extends SpecialAbility

const RED_MANA_EFFECT = preload("res://Player/Abilities/SpecialAbilities/RedBowAbility/RedManaEffect.tscn")

func activate_special_ability(_player: Player) -> void:

	if _player.unlimited_mana_effect == null:
		var red_mana_effect = RED_MANA_EFFECT.instantiate()
		_player.add_child(red_mana_effect)
		_player.unlimited_mana_effect = red_mana_effect
	_player.start_unlimited_mana()
	_player.mana_bar.set_value_to_max()
	pass
