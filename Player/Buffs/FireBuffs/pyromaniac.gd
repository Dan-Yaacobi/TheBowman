class_name Pyromaniac extends Buff

const EXPLOSIVE_ARROWS = preload("res://Player/Buffs/FireBuffs/ExplosiveArrows.tscn")

func check_end_conditions() -> bool:
	if stacks >= max_stacks:
		EventBus.add_player_buff.emit(EXPLOSIVE_ARROWS.instantiate())
		return true
	return false
