class_name SkullAttackAbility extends PlayerShootAbility

const SKULL_ATTACK = preload("uid://5cgvcef7tnv")

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _target and _arrow:
		if _target is Enemy:
			var skull_attack = SKULL_ATTACK.instantiate()
			skull_attack.global_position = _target.global_position
			EventBus.summon_effect.emit(skull_attack)
			
func get_tooltip() -> String:
	return "Apply Weakness on Hit"
