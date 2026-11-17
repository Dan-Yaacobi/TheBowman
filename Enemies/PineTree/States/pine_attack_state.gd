class_name PineAttackState extends EnemyState
## Awake: throws a pinecone every throw_cooldown, swipes when the player is right next to it,
## and falls back asleep once the player has stayed out of sleep_range for sleep_delay.

@export var swipe_state: EnemyState
@export var sleep_state: EnemyState

var pine: PineTree
var _throw_cooldown_left: float = 0.0
var _windup_left: float = -1.0


func init() -> void:
	pine = enemy as PineTree


func Enter() -> void:
	_windup_left = -1.0
	_throw_cooldown_left = minf(_throw_cooldown_left, pine.pine_data.throw_cooldown * 0.5)
	pine.animation_player.play(&"Idle")


func Physics(delta: float) -> EnemyState:
	var data: PineTreeData = pine.pine_data
	pine.face_the_player()
	if pine.should_sleep(delta):
		return sleep_state
	if pine.swipe_cooldown_left <= 0.0 and pine.is_player_in_swipe_range():
		return swipe_state
	if _windup_left >= 0.0:
		_windup_left -= delta
		if _windup_left < 0.0:
			pine.throw_pinecone()
			_throw_cooldown_left = data.throw_cooldown
			pine.animation_player.play(&"Idle")
		return null
	_throw_cooldown_left -= delta
	if _throw_cooldown_left <= 0.0 and pine.calculate_distance_to_player() <= data.sleep_range:
		_windup_left = data.throw_windup
		pine.animation_player.play(&"Throw", -1, 0.35 / maxf(data.throw_windup, 0.01))
	return null
