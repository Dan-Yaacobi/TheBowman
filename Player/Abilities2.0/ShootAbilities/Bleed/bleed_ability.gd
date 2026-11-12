class_name BleedAbility extends PlayerShootAbility

const BLEED_DEBUFF = preload("uid://b0pv21kfxpvci")

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	apply_quiver_debuff(_target)

func applies_quiver_debuff() -> bool:
	return true

func apply_quiver_debuff(_target: Node2D) -> void:
	if _target and _target is Enemy:
		var bleed_debuff: BleedDebuff = BLEED_DEBUFF.instantiate()
		@warning_ignore("narrowing_conversion")
		bleed_debuff.bleed_damage = maxi(1, roundi(PlayerManager.player.stats.bleed_damage.value() * power()))
		var duration: float = PlayerManager.player.stats.bleed_duration.value()
		var ticks: float = PlayerManager.player.stats.dot_ticks("bleed")
		_target.debuff_handler.add_debuff(bleed_debuff,CustomVariables.BLEED_DEBUFF_ID,duration,ticks)
		
func get_tooltip() -> String:
	return "Applies Bleed on hit."

func get_tooltip_color() -> Color:
	return Color.CRIMSON
