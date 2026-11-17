class_name PineWakeState extends EnemyState
## Grows its arms (the telegraph that it's about to attack), then starts attacking.

@export var next_state: EnemyState

var pine: PineTree
var _time_left: float = 0.0


func init() -> void:
	pine = enemy as PineTree


func Enter() -> void:
	_time_left = pine.pine_data.wake_time
	pine.face_the_player()
	pine.animation_player.play(&"Wake", -1, 0.5 / maxf(_time_left, 0.01))


func Physics(delta: float) -> EnemyState:
	_time_left -= delta
	if _time_left <= 0.0:
		return next_state
	return null
