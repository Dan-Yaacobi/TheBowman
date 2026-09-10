class_name StunAbility extends PlayerShootAbility

const STUN_DEBUFF = preload("uid://c1gcykybdcokh")

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _target and _arrow:
		if _target is Enemy:
			if _target.full_health() and _target.can_be_stunned():
				var stun_debuff: Debuff = STUN_DEBUFF.instantiate()
				_target.debuff_handler.add_debuff(stun_debuff,CustomVariables.STUN_DEBUFF_ID,3,1)
				
func get_tooltip() -> String:
	return "Arrows stun full-health enemies"
