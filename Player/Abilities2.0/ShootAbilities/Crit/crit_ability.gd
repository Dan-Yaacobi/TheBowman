class_name CriticalHitAbility extends PlayerAbility

const CRIT = preload("uid://dvpa8tuvsardc")

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy and _activator and _activator is HurtBox:
		if randf_range(0,100) < PlayerManager.player.stats.crit_chance.value():
			_activator.damage_multiplier.append(PlayerManager.player.stats.crit_modifier.value())
			_activator.combat_text_color = Color.PURPLE
			crit_effect(_target)
			
func get_tooltip() -> String:
	return "Crit Chance: "  + "%"

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT
	
func crit_effect(_body: Enemy) -> void:
	var _crit_effect = CRIT.instantiate()
	_crit_effect.global_position = _body.global_position
	EventBus.summon_effect.emit(_crit_effect)
