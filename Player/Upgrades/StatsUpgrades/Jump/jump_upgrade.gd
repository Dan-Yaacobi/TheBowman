class_name PlayerJumpUpgrade extends PlayerUpgrade

@export var amount: int

func upgrade(_player: Player) -> void:
	if _player != null:
		_player.upgrade_stat("jumps", amount)

func get_current(_player: Player) -> String:
	if _player != null:
		return str(_player.stats.max_jumps)
	return ""
	
