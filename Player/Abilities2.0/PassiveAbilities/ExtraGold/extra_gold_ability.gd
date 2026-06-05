class_name ExtraGoldAbility extends PlayerAbility

var total_aquired: int = 1

func update_ability(_amount = 1) -> void:
	total_aquired += _amount

func get_tooltip() -> String:
	return "Extra Gold: " + str(total_aquired)
