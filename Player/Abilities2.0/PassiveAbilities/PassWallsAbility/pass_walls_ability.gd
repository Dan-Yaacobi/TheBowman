class_name PassWallsAbility extends PlayerPassiveAbility

func on_equipped() -> void:
	PlayerManager.player.stats.can_pass_walls = true

func on_unequipped() -> void:
	PlayerManager.player.stats.can_pass_walls = false
	
func get_tooltip() -> String:
	return "Arrows pass through walls"
