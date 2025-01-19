class_name UpgradeKnockback extends UpgradeFunction

func upgrade(_player: Player) -> int:
	var new_cost: int
	new_cost = pow(_player.stats.knockback_resistance,3)
	return new_cost
