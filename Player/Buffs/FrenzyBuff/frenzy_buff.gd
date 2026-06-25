class_name FrenzyBuff extends Buff

func start_buff_effect() -> void:
	apply_buff_effect()

func apply_buff_effect() -> void:
	PlayerManager.player.stats.pull_speed.add_buff(ID, 3.0, Stat.buff_type.MULTIPLICATIVE)

func check_end_conditions() -> bool:
	return time_accumulator >= duration

func extra_end_buff_methods() -> void:
	PlayerManager.player.stats.pull_speed.remove_buff_completly(ID, Stat.buff_type.MULTIPLICATIVE)
