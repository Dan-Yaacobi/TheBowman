class_name PlayerMoveSpeedUpgrade extends PlayerUpgrade

@export var amount: int

func upgrade(_player: Player) -> void:
	if _player != null:
		_player.upgrade_stat("move speed", amount)

func get_current(_player: Player) -> String:
	if _player != null:
		return str(_player.stats.move_speed)
	return ""
