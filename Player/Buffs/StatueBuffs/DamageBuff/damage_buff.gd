class_name DamageBuff extends Buff

var end: bool = false

func start_buff_effect() -> void:
	apply_buff_effect()
	EventBus.in_main_menu.connect(end_buff)

func apply_buff_effect() -> void:
	PlayerManager.player.stats.arrow_damage.add_buff(ID,3,Stat.buff_type.ADDITIVE)

func check_end_conditions() -> bool:
	return end

func end_buff() -> void:
	end = true
	
func extra_end_buff_methods() -> void:
	PlayerManager.player.stats.arrow_damage.remove_buff_completly(ID,Stat.buff_type.ADDITIVE)
