class_name Slow extends Node2D

@onready var player: Player = $"../.."
@onready var timer: Timer = $Timer

var intial_speed: int
var debuff_effect: Node2D
var player_slowed: bool = false
func _ready() -> void:
	timer.timeout.connect(slow_ended)
	
func slow_player(slow_time: float, effect: Node2D) -> void:
	if not player_slowed:
		player_slowed = true
		if effect != null:
			debuff_effect = effect
			player.add_child(debuff_effect)
			debuff_effect.global_position = player.global_position

	
	timer.wait_time = slow_time
	if timer.is_stopped():
		timer.start()
	
func slow_ended() -> void:
	player_slowed = false
	debuff_effect.queue_free()
	timer.stop()

	pass
	
