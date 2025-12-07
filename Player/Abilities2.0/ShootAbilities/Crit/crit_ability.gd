class_name CriticalHitAbility extends PlayerShootAbility

var crit_chance: int = 5

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability() -> void:
	if can_activate and arrow:
		arrow.crit_chance += crit_chance

func update_ability(_amount = 0) -> void:
	crit_chance+= randi_range(1,4)

func get_tooltip() -> String:
	return "Crit Chance: " + str(crit_chance) + "%"
