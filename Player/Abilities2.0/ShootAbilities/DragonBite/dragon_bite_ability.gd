class_name DragonBiteAbility extends PlayerShootAbility

const DRAGON_BITE = preload("uid://cmv8qrto4g6en")


func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _arrow:
		if _arrow.perfect_shot:
			var dragon_bite: DragonBite = DRAGON_BITE.instantiate()
			dragon_bite.set_damage(_arrow.damage)
			dragon_bite.direction = _arrow.velocity.normalized()
			dragon_bite.global_position = PlayerManager.player.global_position
			_arrow.queue_free()
			EventBus.summon_effect.emit(dragon_bite)

func get_tooltip() -> String:
	return "Bleeding Wounds: Damaged enemies bleed on hit."
