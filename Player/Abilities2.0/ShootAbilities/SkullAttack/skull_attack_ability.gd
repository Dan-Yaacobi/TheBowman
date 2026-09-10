class_name SkullAttackAbility extends PlayerShootAbility

const SKULL_ATTACK = preload("uid://5cgvcef7tnv")

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _target:
		if _target is Enemy:
			var skull_attack = SKULL_ATTACK.instantiate()
			skull_attack.global_position = _target.global_position
			EventBus.summon_effect.emit(skull_attack)
			
func get_tooltip() -> String:
	return "Apply Weakness on Hit"
