class_name BarrageAbility extends ActiveAbility

@export var arrow_count: int = 10
@export var interval: float = 0.12

func _ready() -> void:
	print("barrage ready")
func activate(_player: Player) -> void:
	_barrage(_player)

func _barrage(_player: Player) -> void:
	for i in arrow_count:
		var direction: Vector2 = (_player.get_global_mouse_position() - _player.global_position).normalized()
		if not is_instance_valid(_player):
			return
		_player.main_hand.fire_at(direction, 1.0)
		await _player.get_tree().create_timer(interval).timeout
