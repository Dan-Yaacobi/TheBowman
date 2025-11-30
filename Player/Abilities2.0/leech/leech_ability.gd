class_name LeechAbility extends PlayerShootAbility

var leech_chance: int = 5

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability(_arrow: Arrow) -> void:
	if activated:
		_arrow.leech_chance = leech_chance

func update_ability() -> void:
	leech_chance+= randi_range(1,4)

func get_tooltip() -> String:
	return "Leech Chance: " + str(leech_chance) + "%"
