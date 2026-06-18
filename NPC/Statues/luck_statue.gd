class_name LuckStatue extends NPC

const LUCK_BUFF = preload("uid://pb76bqqhr3hp")

func action(_index: int) -> void:
	match _index:
		0:
			_luck_buff()

func _luck_buff() -> void:
	var buff: Buff = LUCK_BUFF.instantiate()
	EventBus.add_player_buff.emit(buff)
	show_post_action_line()
	action_taken = true
