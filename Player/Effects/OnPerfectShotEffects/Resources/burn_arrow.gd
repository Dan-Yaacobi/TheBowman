class_name BurnArrowPerfectEffect extends OnPerfectShotEffect

var burn_buff: Buff

func apply_effect(_target: Node2D, _arrow: Arrow) -> void:
	burn_buff = effect.instantiate()
	EventBus.arrow_hit_enemy.connect(remove_buff)
	EventBus.add_player_buff.emit(burn_buff)

	
func remove_buff(_arrow: Arrow) -> void:
	if is_instance_valid(burn_buff):
		burn_buff.buff_over.emit(burn_buff.ID)
		burn_buff.buff_end()
	EventBus.arrow_hit_enemy.disconnect(remove_buff)

	
