class_name SwordBleedAbility extends PlayerSwordAbility

var sword_bleed_chance: float = 5

func add_ability() -> void:
	PlayerManager.player.add_sword_ability(self)
	
func activate_ability() -> void:
	if can_activate:
		PlayerManager.player.get_sword().set_bleed_chance(sword_bleed_chance)

func update_ability(amount = 0) -> void:
	sword_bleed_chance += randi_range(1,4)

func get_tooltip() -> String:
	return "Sword Bleed Chance: " + str(sword_bleed_chance)
