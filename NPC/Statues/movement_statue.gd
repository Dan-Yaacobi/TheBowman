class_name MovementStatue extends NPC

const DASH_BUFF = preload("uid://bdttqy1rdab0j")

func action(_index: int) -> void:
	match _index:
		0:
			_movement_buff()

func _movement_buff() -> void:
	var buff: Buff = DASH_BUFF.instantiate()
	EventBus.add_player_buff.emit(buff)
	show_post_action_line()
	action_taken = true
