class_name BalloonBlowState extends EnemyState
@onready var seek: BalloonSeekState = $"../Seek"
@onready var blow_timer: Timer = $BlowTimer
@onready var idle: BalloonIdleState = $"../Idle"

const GROW_SPEED: float = 150.0

func init() -> void:
	blow_timer.timeout.connect(seeking)

func Enter() -> void:
	blow_timer.start()
	enemy.update_animation("Blow")
	var dir = enemy.calculate_direction_to_player()
	enemy.wind.enable(dir)

func Exit() -> void:
	blow_timer.stop()
	enemy.wind.disable()

func Process(_delta: float) -> EnemyState:
	return null

func Physics(_delta: float) -> EnemyState:
	var dir_to_player = enemy.calculate_direction_to_player()
	enemy.velocity = -dir_to_player * (enemy.blow_force / 3.0) * _delta
	enemy.wind.grow(GROW_SPEED * _delta)
	return null

func seeking() -> void:
	state_machine.ChangeState(seek)
