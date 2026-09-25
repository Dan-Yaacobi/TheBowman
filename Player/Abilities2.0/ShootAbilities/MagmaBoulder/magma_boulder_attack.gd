class_name MagmaBoulderAttaack extends PlayerShootAbility

const MAGMA_BOULDER = preload("uid://esq83otc8iu8")

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _activator and _activator is Arrow and _activator.perfect_shot:
		var magma_boulder: MagmaBoulder = MAGMA_BOULDER.instantiate()
		magma_boulder.damage = roundi(_activator.damage * 1.2)
		magma_boulder.direction = _activator.velocity.normalized()
		magma_boulder.global_position = PlayerManager.player.global_position
		magma_boulder.after_hit_abilities = _activator.after_hit_abilities
		magma_boulder.before_hit_abilities = _activator.before_hit_abilities
		magma_boulder.knockback_power = _activator.knockback
		_activator.queue_free()
		EventBus.summon_effect.emit(magma_boulder)


func get_tooltip() -> String:
	return "Bleeding Wounds: Damaged enemies bleed on hit."
