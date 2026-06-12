class_name DoubleJumpAbility extends PlayerPassiveAbility

func on_equipped() -> void:
	PlayerManager.player.stats.max_jumps += 1

func on_unequipped() -> void:
	PlayerManager.player.stats.max_jumps -= 1

func get_tooltip() -> String:
	return "Double Jump"
