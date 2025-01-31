class_name PlayerHpUpgrade extends PlayerUpgrade

@export var amount: int

func upgrade(_player: Player) -> void:
	if _player != null:
		_player.upgrade_stat("hp", amount)

func get_current(_player: Player) -> String:
	if _player != null:
		return str(_player.stats.max_hp)
	return ""
