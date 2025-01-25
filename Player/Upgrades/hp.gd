class_name PlayerHpUpgrade extends PlayerUpgrade

func upgrade(_player: Player) -> void:
	if _player != null:
		_player.stats.max_hp += 1
		_player.health_bar._set_health(_player.stats.max_hp)
