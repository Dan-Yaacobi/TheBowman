class_name SwordSizeAbility extends PlayerSwordAbility

var sword_size: float = 0.1

func add_ability() -> void:
	PlayerManager.player.add_sword_ability(self)
	
func activate_ability() -> void:
	if activated:
		PlayerManager.player.set_sword_size(sword_size)
	else:
		PlayerManager.player.set_sword_size(-sword_size)

func update_ability() -> void:
	sword_size += 0.1

func get_tooltip() -> String:
	return "Sword Size: " + str(PlayerManager.player.stats.sword_size + sword_size)
