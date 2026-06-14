class_name PierceAbility extends PlayerShootAbility

var id: int = 998

func on_equipped() -> void:
	PlayerManager.player.stats.arrow_pierce.add_buff(id,2.0,Stat.buff_type.ADDITIVE)

func on_unequipped() -> void:
	PlayerManager.player.stats.arrow_pierce.remove_buff_stack(id,Stat.buff_type.ADDITIVE)

func get_tooltip() -> String:
	return "Piercing shot: Arrows pierce 2 addiontal enemies."
