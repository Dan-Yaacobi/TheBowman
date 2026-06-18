class_name DamageStatue extends NPC

const DAMAGE_BUFF = preload("uid://dgj53e103va4p")

func action(_index: int) -> void:
	match _index:
		0:
			_damage_buff()

func _damage_buff() -> void:
	var buff: Buff = DAMAGE_BUFF.instantiate()
	EventBus.add_player_buff.emit(buff)
	show_post_action_line()
	action_taken = true
