class_name ExtraArrowAbility extends PlayerPassiveAbility

@export var id: int = 999

func on_equipped() -> void:
	PlayerManager.player.stats.arrow_count.add_buff(id, 1.0, Stat.buff_type.ADDITIVE)

func on_unequipped() -> void:
	PlayerManager.player.stats.arrow_count.remove_buff_stack(id,Stat.buff_type.ADDITIVE)

func get_tooltip() -> String:
	return "Fires one additional arrow."
