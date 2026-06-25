class_name ExtraArrowActiveAbility extends ActiveAbility
@export var ID: int = 1390

func on_equipped(_player: Player) -> void:
	_player.stats.arrow_count.add_buff(ID, 1, Stat.buff_type.ADDITIVE)

func on_unequipped(_player: Player) -> void:
	_player.stats.arrow_count.remove_buff_completly(ID, Stat.buff_type.ADDITIVE)
