class_name NotPerfectPoisonAbility extends PlayerShootAbility

const POISON_DEBUFF = preload("uid://dw404fcvhcw52")

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _target and _arrow:
		if _target is Enemy and not _arrow.perfect_shot:
			var poison_debuff: Debuff = POISON_DEBUFF.instantiate()
			poison_debuff.poison_damage = 2
			_target.debuff_handler.add_debuff(poison_debuff,5,5 )
			
func get_tooltip() -> String:
	return "Perfect shots inflict poison."
