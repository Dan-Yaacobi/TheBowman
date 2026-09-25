class_name PoisonAbility extends PlayerShootAbility

const POISON_DEBUFF = preload("uid://dw404fcvhcw52")

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy:
		if _activator is Arrow and _activator.perfect_shot:
			var poison_debuff: Debuff = POISON_DEBUFF.instantiate()
			poison_debuff.poison_damage = PlayerManager.player.stats.poison_damage.value()
			var duration = PlayerManager.player.stats.poison_duration.value()
			var ticks = PlayerManager.player.stats.poison_ticks.value()
			_target.debuff_handler.add_debuff(poison_debuff,CustomVariables.POISON_DEBUFF_ID,duration,ticks)
			
func get_tooltip() -> String:
	return "Perfect shots inflict poison."
