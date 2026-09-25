class_name BleedAbility extends PlayerShootAbility

const BLEED_DEBUFF = preload("uid://b0pv21kfxpvci")

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy and _target.is_damaged():
		var bleed_debuff: BleedDebuff = BLEED_DEBUFF.instantiate()
		@warning_ignore("narrowing_conversion")
		bleed_debuff.bleed_damage = PlayerManager.player.stats.bleed_damage.value()
		var duration: float = PlayerManager.player.stats.bleed_duration.value()
		var ticks: float = PlayerManager.player.stats.bleed_ticks.value()
		_target.debuff_handler.add_debuff(bleed_debuff,CustomVariables.BLEED_DEBUFF_ID,duration,ticks)
		
func get_tooltip() -> String:
	return "Bleeding Wounds: Damaged enemies bleed on hit."
