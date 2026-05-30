class_name SwordSizeAbility extends PlayerSwordAbility

var sword_size: float = 0.1

func add_ability() -> void:
	PlayerManager.player.add_sword_ability(self)
	
func activate_ability() -> void:
	if can_activate:
		PlayerManager.player.set_sword_size(sword_size)
	else:
		PlayerManager.player.set_sword_size(-sword_size)

func update_ability(_amount = 0) -> void:
	sword_size += randf_range(0.05,0.1)

func get_tooltip() -> String:
	return "Sword Size: " + str(PlayerManager.player.stats.sword_size.value() + sword_size)
