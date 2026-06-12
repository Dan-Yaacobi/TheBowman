class_name BalloonIdleState extends EnemyState
@onready var seek: BalloonSeekState = $"../Seek"

func init() -> void:
	state_machine.pausing.connect(change_to_idle)

func Enter() -> void:
	enemy.update_animation("Idle")
	
func Exit() -> void:
	pass	
func Process(_delta: float) -> EnemyState:
	return null
	
func Physics(_delta: float) -> EnemyState:
	enemy.apply_drift(_delta)
	var dir = enemy.calculate_direction_to_player()
	enemy.velocity.x = dir.x * enemy.stats.move_speed.value() * 0.3
	if enemy.interaction_detector.has_overlapping_bodies():
		for body in enemy.interaction_detector.get_overlapping_bodies():
			if body is Player:
				return seek
	return null


func change_to_idle(_stop: bool) -> void:
	if _stop:
		state_machine.ChangeState(self)
