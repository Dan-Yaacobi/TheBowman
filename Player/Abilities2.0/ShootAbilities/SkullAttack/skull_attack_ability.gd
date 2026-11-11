class_name SkullAttackAbility extends PlayerShootAbility

const SKULL_ATTACK = preload("uid://5cgvcef7tnv")

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	apply_quiver_debuff(_target)

func applies_quiver_debuff() -> bool:
	return true

func apply_quiver_debuff(_target: Node2D) -> void:
	if _target and _target is Enemy:
		var skull_attack = SKULL_ATTACK.instantiate()
		skull_attack.global_position = _target.global_position
		EventBus.summon_effect.emit(skull_attack)
		
func get_tooltip() -> String:
	return "Apply Cursed on Hit, Cursed enemies take more damage but also deal more."

func get_tooltip_color() -> Color:
	return Color.MEDIUM_ORCHID
