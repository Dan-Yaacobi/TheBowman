class_name LuckBuff extends Buff

var end: bool = false
func start_buff_effect() -> void:
	PlayerManager.player.stats.extra_drop_chance.add_buff(ID,10,Stat.buff_type.ADDITIVE)
	EventBus.in_main_menu.connect(end_buff)
	
func check_end_conditions() -> bool:
	return end

func end_buff() -> void:
	end = true
	
func extra_end_buff_methods() -> void:
	PlayerManager.player.stats.extra_drop_chance.remove_buff_stack(ID,Stat.buff_type.ADDITIVE)
