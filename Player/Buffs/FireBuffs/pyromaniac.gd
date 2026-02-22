class_name Pyromaniac extends Buff

const EXPLOSIVE_ARROWS = preload("res://Player/Buffs/FireBuffs/ExplosiveArrows.tscn")

func start_buff_effect() -> void:
	if stacks >= max_stacks:
		buff_end()

func extra_end_buff_methods() -> void:
	EventBus.add_player_buff.emit(EXPLOSIVE_ARROWS.instantiate())
