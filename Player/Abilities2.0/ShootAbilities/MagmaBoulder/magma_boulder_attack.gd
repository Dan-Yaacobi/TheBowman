class_name MagmaBoulderAttaack extends PlayerShootAbility

const MAGMA_BOULDER = preload("uid://esq83otc8iu8")

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _arrow:
		if _arrow.perfect_shot:
			var magma_boulder: MagmaBoulder = MAGMA_BOULDER.instantiate()
			magma_boulder.damage = roundi(_arrow.damage * 1.2)
			magma_boulder.direction = _arrow.velocity.normalized()
			magma_boulder.global_position = PlayerManager.player.global_position
			_arrow.queue_free()
			EventBus.summon_effect.emit(magma_boulder)


func get_tooltip() -> String:
	return "Bleeding Wounds: Damaged enemies bleed on hit."
