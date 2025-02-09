class_name HealthGainEffect extends Sprite2D

var player: Player
@onready var area: Area2D = $Area2D
var heal_amount: int = 1

func _ready() -> void:
	area.body_entered.connect(heal_player)
	
func set_positions(_player: Player, start_pos: Vector2):
	global_position = start_pos
	player = _player

func _physics_process(delta: float) -> void:
	global_position += Vector2(player.global_position - global_position).normalized()
	pass
	
func heal_player(b) -> void:
	if b is Player:
		b.heal(heal_amount)
		queue_free()
	pass
