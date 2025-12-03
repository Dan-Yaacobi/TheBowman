class_name PlayerShootAbility extends PlayerAbility

var arrow: Arrow

func get_arrow(_arrow: Arrow) -> void:
	if _arrow:
		arrow = _arrow
