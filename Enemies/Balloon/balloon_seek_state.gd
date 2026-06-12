class_name BalloonSeekState extends EnemyState

@onready var pre_blow: BalloonPreBlowState = $"../PreBlow"

func init() -> void:
	pass

func Enter() -> void:
	enemy.update_animation("Seek")
	
func Exit() -> void:
	pass	
func Process(_delta: float) -> EnemyState:
	return null
	
func Physics(_delta: float) -> EnemyState:
	var player_pos = PlayerManager.player.global_position
	var radius = enemy.blowing_detector.get_child(0).shape.radius / 2
	var left_target = Vector2(player_pos.x - radius, player_pos.y)
	var right_target = Vector2(player_pos.x + radius, player_pos.y)
	var dl = enemy.global_position.distance_to(left_target)
	var dr = enemy.global_position.distance_to(right_target)
	var target = left_target if dl < dr else right_target
	var to_target = target - enemy.global_position
	enemy.velocity = to_target.normalized() * enemy.stats.move_speed.value()
	
	if enemy.blowing_detector.has_overlapping_bodies():
		if abs(enemy.global_position.y - player_pos.y) <= 10.0:
			enemy.wind.face_player()
			return pre_blow
	return null
	
