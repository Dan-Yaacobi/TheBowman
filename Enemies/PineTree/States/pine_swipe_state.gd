class_name PineSwipeState extends EnemyState
## Wind-up, a short window where the swipe can hit (strong knockback toward the edge), recovery.

enum Phase { WINDUP, ACTIVE, RECOVERY }

@export var attack_state: EnemyState

var pine: PineTree
var _phase: Phase = Phase.WINDUP
var _time_left: float = 0.0


func init() -> void:
	pine = enemy as PineTree


func Enter() -> void:
	pine.face_the_player()
	_phase = Phase.WINDUP
	_time_left = pine.pine_data.swipe_windup
	pine.animation_player.play(&"Swipe", -1, 0.55 / maxf(pine.pine_data.swipe_windup + pine.pine_data.swipe_active, 0.01))


func Exit() -> void:
	pine.set_swipe_active(false)
	pine.swipe_cooldown_left = pine.pine_data.swipe_cooldown


func Physics(delta: float) -> EnemyState:
	_time_left -= delta
	if _time_left > 0.0:
		return null
	match _phase:
		Phase.WINDUP:
			_phase = Phase.ACTIVE
			_time_left = pine.pine_data.swipe_active
			pine.set_swipe_active(true)
		Phase.ACTIVE:
			_phase = Phase.RECOVERY
			_time_left = pine.pine_data.swipe_recovery
			pine.set_swipe_active(false)
		Phase.RECOVERY:
			return attack_state
	return null
