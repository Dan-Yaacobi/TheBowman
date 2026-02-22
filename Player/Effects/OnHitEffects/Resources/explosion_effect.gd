class_name ExplosionEffect extends OnHitEffect

func apply_effect(_target: Node2D, _arrow: Arrow) -> void:
	var new_effect = effect.instantiate()
	new_effect.global_position = _target.global_position
	EventBus.summon_effect.emit(new_effect)
	pass
