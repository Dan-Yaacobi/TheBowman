class_name NotPerfectPoisonAbility extends PlayerShootAbility

const POISON_DEBUFF = preload("uid://dw404fcvhcw52")

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy and _activator.get_parent() is Arrow and not _activator.get_parent().perfect_shot:
		var poison_debuff: Debuff = POISON_DEBUFF.instantiate()
		poison_debuff.poison_damage = PlayerManager.player.stats.poison_damage.value()
		var poison_duration = PlayerManager.player.stats.poison_duration.value()
		var poison_ticks = PlayerManager.player.stats.poison_ticks.value()
		_target.debuff_handler.add_debuff(poison_debuff,CustomVariables.POISON_DEBUFF_ID,poison_duration,poison_ticks )
		
func get_tooltip() -> String:
	return "None Perfect shots inflict poison."

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
	
func get_tooltip_color() -> Color:
	return Color.LIME_GREEN
