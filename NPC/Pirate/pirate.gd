class_name Pirate extends NPC

var buying: bool = false
var gamble_cost: int = 50

func action(_index: int) -> void:
	match _index:
		0:
			_gamble()

func _gamble() -> void:
	if not buying:
		buying = true
		if PlayerManager.player.buy(gamble_cost):
			EventBus.try_drop.emit(global_position,100,1.0)
			show_post_action_line()
			action_taken = true
		buying = false
