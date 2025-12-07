class_name BleedAbility extends PlayerShootAbility

var bleed_chance: int = 5

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability() -> void:
	if can_activate and arrow:
		arrow.bleed_chance += bleed_chance

func update_ability(amount = 0) -> void:
	bleed_chance += randi_range(1,4)

func get_tooltip() -> String:
	return "Bleed Chance: " + str(bleed_chance) + "%"
