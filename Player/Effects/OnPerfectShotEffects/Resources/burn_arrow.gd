class_name BurnArrowPerfectEffect extends OnPerfectShotEffect

func apply_effect(_target: Node2D, _arrow: Arrow) -> void:
	var burn_buff: Buff = effect.instantiate()
	
	EventBus.add_player_buff.emit(burn_buff)
