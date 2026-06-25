class_name CircleShotAbility extends ActiveAbility

@export var arrow_count: int = 12

func activate(_player: Player) -> void:
	var angle_step: float = TAU / arrow_count
	for i in arrow_count:
		var direction: Vector2 = Vector2.RIGHT.rotated(angle_step * i)
		_player.main_hand.fire_at(direction, 1.0)
