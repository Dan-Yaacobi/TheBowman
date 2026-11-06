class_name RockGolemJumpState extends EnemyState
## Crouches, then leaps in an arc onto golem.jump_target. Ends on landing.

@export var land_state: EnemyState
## Ignore the floor this long after take-off, so it doesn't "land" on the spot it left
const TAKEOFF_GRACE: float = 0.1
## Sprite scale at rest; squash and stretch are relative to this
const BASE_SCALE: Vector2 = Vector2(0.4, 0.4)

var golem: RockGolem
var _windup_left: float = 0.0
var _air_time: float = 0.0
var _launched: bool = false
var _squash_tween: Tween


func init() -> void:
	golem = enemy as RockGolem


func Enter() -> void:
	golem.move_x = 0.0
	_launched = false
	_air_time = 0.0
	_windup_left = golem.golem_data.jump_windup
	golem.update_animation("Idle")
	if golem.jump_target:
		golem.face_x(golem.jump_target.get_top_center().x)
	_tween_scale(BASE_SCALE * Vector2(1.12, 0.85), golem.golem_data.jump_windup)


func Exit() -> void:
	golem.move_x = 0.0
	golem.jump_cooldown_left = golem.golem_data.jump_cooldown
	_tween_scale(BASE_SCALE, 0.12)


func Physics(delta: float) -> EnemyState:
	if not _launched:
		if golem.jump_target == null or not is_instance_valid(golem.jump_target):
			return land_state
		_windup_left -= delta
		if _windup_left <= 0.0:
			_launch()
		return null
	_air_time += delta
	if _air_time > TAKEOFF_GRACE and golem.is_on_floor():
		return land_state
	return null


## Ballistic arc that reaches the landing point while coming down (islands are one-way).
func _launch() -> void:
	_launched = true
	var landing: Vector2 = golem.get_landing_point(golem.jump_target)
	var offset: Vector2 = landing - golem.global_position
	var g: float = golem.gravity
	var flight_time: float = clampf(absf(offset.x) / golem.golem_data.jump_speed_x, 0.4, 1.0)
	# Going up, it must still be falling when it arrives
	if offset.y < 0.0:
		flight_time = maxf(flight_time, sqrt(-2.0 * offset.y / g) + 0.12)
	golem.move_x = offset.x / flight_time
	golem.velocity.y = offset.y / flight_time - 0.5 * g * flight_time
	golem.update_animation("Walk")
	_tween_scale(BASE_SCALE * Vector2(0.9, 1.12), 0.12)


func _tween_scale(target: Vector2, duration: float) -> void:
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = golem.create_tween()
	_squash_tween.tween_property(golem.sprite, "scale", target, duration)
