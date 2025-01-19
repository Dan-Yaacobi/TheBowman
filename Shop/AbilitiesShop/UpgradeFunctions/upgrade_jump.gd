class_name UpgradeJump extends UpgradeFunction

func upgrade(_player: Player) -> int:
	var new_cost: int
	new_cost = pow(_player.stats.max_jumps,5)
	return new_cost
