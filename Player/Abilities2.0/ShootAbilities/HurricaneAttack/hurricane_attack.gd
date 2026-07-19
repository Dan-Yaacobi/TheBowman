class_name HurricaneAttack extends PlayerShootAbility

const HURRICANE = preload("uid://cxycop4k7jhcy")

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _arrow:
		if _arrow.perfect_shot:
			var hurricane: Hurricane = HURRICANE.instantiate()
			hurricane.direction = _arrow.velocity.normalized()
			hurricane.global_position = PlayerManager.player.global_position + Vector2(0,25)
			_arrow.queue_free()
			EventBus.summon_effect.emit(hurricane)


func get_tooltip() -> String:
	return "Bleeding Wounds: Damaged enemies bleed on hit."
