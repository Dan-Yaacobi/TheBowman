class_name BirdDiveAttackState extends EnemyState

@onready var seek: BirdSeekState = $"../Seek"

@export var distance_to_stop: int = 10

var target_pos: Vector2
var direction: Vector2

#what happens when we initialize this state
func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	
	direction = enemy.calculate_direction_to_player()
	target_pos = PlayerManager.player.global_position + direction * 10
	enemy.rotation = enemy.calculate_direction_to_player().angle()
	enemy.animation_player.play("Dive")
	
#what happens when the player exits this state
func Exit() -> void:
	enemy.rotation = 0
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	enemy.velocity = direction * enemy.stats.move_speed.value() * 3
	var to_target = target_pos - enemy.global_position
	if to_target.dot(direction) <= 0:
		return seek
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
