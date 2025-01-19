class_name UpgradeHP extends UpgradeFunction

func upgrade(_player: Player) -> int:
	var new_cost: int
	new_cost = pow(_player.stats.hp,3)
	return new_cost
