class_name BurningTrailAbility extends PlayerShootAbility
const BURNING_TRAIL = preload("uid://brqyuwj57wlga")

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _arrow:
		var trail_effect: BurningTrail = BURNING_TRAIL.instantiate()
		_arrow.add_child(trail_effect)
		trail_effect.set_arrow(_arrow)
	
func get_tooltip() -> String:
	return "Arrows leaves a burning trail"
