class_name DotExtendMinor extends MinorAbility
## Non-perfect arrow hits extend burn, bleed and poison already on the enemy by value seconds.

const DOT_IDS: Array[int] = [CustomVariables.BURN_DEBUFF_ID, CustomVariables.BLEED_DEBUFF_ID, CustomVariables.POISON_DEBUFF_ID]

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var arrow: Arrow = MinorHitHelpers.arrow_of(_activator)
	if enemy == null or arrow == null or arrow.perfect_shot or enemy.is_dead:
		return
	for id in DOT_IDS:
		if enemy.has_debuff(id):
			var debuff: Debuff = enemy.debuff_handler.debuffs[id]
			if debuff.tick_interval > 0.0:
				debuff.ticks += ceili(value * power() / debuff.tick_interval)

func get_tooltip() -> String:
	return "Non-perfect hits extend burn, bleed and poison by %ds" % value

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

func get_tooltip_color() -> Color:
	return Color.YELLOW_GREEN
