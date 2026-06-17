class_name BirdbossPositionState extends EnemyState

const FLY_HEIGHT_OFFSET: float = -80.0
const ARRIVAL_THRESHOLD: float = 20.0

@onready var fly: BirdbossFlyState = $"../Fly"

func init() -> void:
	pass

func Enter() -> void:
	enemy.animation_player.play("Fly")

func Exit() -> void:
	pass

func Process(_delta: float) -> EnemyState:
	return null

func Physics(_delta: float) -> EnemyState:
	var target: Vector2 = Vector2(
		PlayerManager.player.global_position.x,
		PlayerManager.player.global_position.y + FLY_HEIGHT_OFFSET
	)
	var diff: Vector2 = target - enemy.global_position

	if diff.length() < ARRIVAL_THRESHOLD:
		return fly

	enemy.velocity = diff.normalized() * enemy.stats.move_speed.value()
	return null
