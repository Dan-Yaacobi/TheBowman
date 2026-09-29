class_name CritResetAbility extends PlayerAbility

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _activator and _activator is HurtBox:
		_activator.damage_multiplier.erase(PlayerManager.player.stats.crit_modifier.value())

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
