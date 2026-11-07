class_name SacrificialAltar extends NPC

signal sacrificed

## The altar never takes the last heart container.
@export var refuse_line: String = "The well stirs, then stills. You have nothing left to give."

var _sacrificing: bool = false

func action(_index: int) -> void:
	match _index:
		0:
			_sacrifice()

func _sacrifice() -> void:
	if _sacrificing or action_taken:
		return
	var player: Player = PlayerManager.player
	if _heart_containers(player) <= 1:
		chat_box.show_line(refuse_line)
		return
	_sacrificing = true
	player.lose_heart()
	action_taken = true
	_play_animation("used")
	show_post_action_line()
	sacrificed.emit()
	_sacrificing = false

func _heart_containers(player: Player) -> int:
	return ceili(float(player.max_hp_value()) / CustomVariables.HP_PER_HEART)

func on_interaction_opened() -> void:
	if not action_taken:
		_play_animation("interact")

func on_interaction_closed() -> void:
	if not action_taken:
		_play_animation("idle")
