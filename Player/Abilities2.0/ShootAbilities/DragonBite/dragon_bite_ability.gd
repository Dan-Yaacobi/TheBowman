class_name DragonBiteAbility extends PlayerShootAbility

const DRAGON_BITE = preload("uid://cmv8qrto4g6en")


func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _activator and _activator is Arrow and _activator.perfect_shot:
		var dragon_bite: DragonBite = DRAGON_BITE.instantiate()
		dragon_bite.set_damage(_activator.damage)
		dragon_bite.direction = _activator.velocity.normalized()
		dragon_bite.global_position = PlayerManager.player.global_position
		dragon_bite.after_hit_abilities = _activator.after_hit_abilities
		dragon_bite.before_hit_abilities = _activator.before_hit_abilities
		
		_activator.queue_free()
		EventBus.summon_effect.emit(dragon_bite)

func get_tooltip() -> String:
	return "Turns Perfect Shots to a Dragon"
