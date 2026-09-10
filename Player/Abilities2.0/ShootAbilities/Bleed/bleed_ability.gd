class_name BleedAbility extends PlayerShootAbility

const BLEED_DEBUFF = preload("uid://b0pv21kfxpvci")

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _target:
		if _target is Enemy:
			print(_target.is_damaged(), " " , _target.current_hp, " ", _target.stats.max_hp)
			if _target.is_damaged():
				var bleed_debuff: BleedDebuff = BLEED_DEBUFF.instantiate()
				bleed_debuff.bleed_damage = 2
				_target.debuff_handler.add_debuff(bleed_debuff,CustomVariables.BLEED_DEBUFF_ID,5,5)
				
func get_tooltip() -> String:
	return "Bleeding Wounds: Damaged enemies bleed on hit."
