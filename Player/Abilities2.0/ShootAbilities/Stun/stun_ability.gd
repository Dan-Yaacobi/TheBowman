class_name StunAbility extends PlayerShootAbility

const STUN_DEBUFF = preload("uid://c1gcykybdcokh")

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _target and _arrow:
		if _target is Enemy:
			if _target.full_health() and _target.can_be_stunned():
				var stun_debuff: Debuff = STUN_DEBUFF.instantiate()
				_target.debuff_handler.add_debuff(stun_debuff,3,1)
				
func get_tooltip() -> String:
	return "Arrows stun full-health enemies"
