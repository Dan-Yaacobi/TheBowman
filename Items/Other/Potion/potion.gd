class_name Potion extends Item

var _bob_time: float = 0.0
var heal_amount: int
@export var bob_speed: float = 2.0
@export var bob_height: float = 3.0

func extra_ready_functions() -> void:
	heal_amount = PlayerManager.player.stats.rift_level
	
func extra_process_functions(_delta: float) -> void:
	_bob_time += _delta
	position.y += sin(_bob_time * bob_speed) * bob_height * _delta
	magnet_area.monitoring = _player.can_heal(heal_amount)

func _collect() -> void:
	if _player.heal(heal_amount):
		queue_free()
