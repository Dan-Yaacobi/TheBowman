class_name HurricaneAttack extends PlayerShootAbility

const HURRICANE = preload("uid://cxycop4k7jhcy")

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _activator and _activator is Arrow and _activator.perfect_shot:
		var hurricane: Hurricane = HURRICANE.instantiate()
		hurricane.direction = _activator.velocity.normalized()
		hurricane.global_position = PlayerManager.player.global_position + Vector2(0,25)
		hurricane.after_hit_abilities = _activator.after_hit_abilities
		hurricane.before_hit_abilities = _activator.before_hit_abilities
		hurricane.knockback_power = _activator.knockback
		_activator.queue_free()
		EventBus.summon_effect.emit(hurricane)


func get_tooltip() -> String:
	return "Bleeding Wounds: Damaged enemies bleed on hit."
