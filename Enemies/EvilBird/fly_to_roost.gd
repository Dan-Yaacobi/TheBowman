class_name BirdFlyToRoostState extends EnemyState

var roost_target: Vector2

func init() -> void:
	pass

func Enter() -> void:
	enemy.animation_player.play("Fly")

func Exit() -> void:
	pass

func Process(_delta: float) -> EnemyState:
	return null

func Physics(_delta: float) -> EnemyState:
	var diff: Vector2 = roost_target - enemy.global_position
	enemy.velocity = diff.normalized() * enemy.stats.move_speed.value()
	return null
