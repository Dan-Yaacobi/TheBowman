class_name RockGolemJumpState extends EnemyState
## Heavy leap onto golem.jump_target: long crouch, slow lift-off, hang, then a drop
## onto the island, a landing squash and a short recovery.
## The arc is scripted (not physics) so the easing is exact.

@export var land_state: EnemyState
## Sprite scale at rest; squash and stretch are relative to this
const BASE_SCALE: Vector2 = Vector2(0.4, 0.4)
## Small downward speed on landing so the body settles onto the island
const LANDING_SETTLE_SPEED: float = 40.0

enum Phase { WINDUP, AIR, RECOVER }

var golem: RockGolem
var _phase: Phase = Phase.WINDUP
var _time_left: float = 0.0
var _progress: float = 0.0
var _duration: float = 1.0
var _start: Vector2 = Vector2.ZERO
var _landing_x: float = 0.0
var _arc_height: float = 0.0
var _squash_tween: Tween


func init() -> void:
	golem = enemy as RockGolem


func Enter() -> void:
	golem.move_x = 0.0
	_phase = Phase.WINDUP
	_time_left = golem.golem_data.jump_windup
	golem.update_animation("Idle")
	if golem.jump_target:
		golem.face_x(golem.jump_target.get_top_center().x)
	_tween_scale(BASE_SCALE * Vector2(1.18, 0.78), golem.golem_data.jump_windup, Tween.EASE_OUT)


func Exit() -> void:
	golem.is_leaping = false
	golem.move_x = 0.0
	golem.jump_cooldown_left = golem.golem_data.jump_cooldown
	_tween_scale(BASE_SCALE, 0.15, Tween.EASE_OUT)


func Physics(delta: float) -> EnemyState:
	match _phase:
		Phase.WINDUP:
			if not _target_valid():
				return land_state
			_time_left -= delta
			if _time_left <= 0.0:
				_launch()
		Phase.AIR:
			if not _target_valid():
				# Island gone mid-air: drop and let gravity decide
				golem.is_leaping = false
				return land_state
			_progress = minf(_progress + delta / _duration, 1.0)
			golem.global_position = _arc_point(_progress)
			if _progress >= 1.0:
				_land()
		Phase.RECOVER:
			_time_left -= delta
			if _time_left <= 0.0:
				return land_state
	return null


func _target_valid() -> bool:
	return golem.jump_target != null and is_instance_valid(golem.jump_target) \
		and golem.jump_target.is_solid()


func _launch() -> void:
	var data: RockGolemData = golem.golem_data
	var landing: Vector2 = golem.get_landing_point(golem.jump_target)
	_start = golem.global_position
	_landing_x = landing.x
	_duration = clampf(absf(landing.x - _start.x) / data.jump_speed_x, data.jump_min_time, data.jump_max_time)
	# Rise above whichever end is higher (smaller y)
	_arc_height = data.jump_arc_height + maxf(_start.y - landing.y, 0.0) * 0.5
	_progress = 0.0
	_phase = Phase.AIR
	golem.is_leaping = true
	golem.velocity = Vector2.ZERO
	golem.knockback_velocity = Vector2.ZERO
	golem.update_animation("Walk")
	_tween_scale(BASE_SCALE * Vector2(0.88, 1.14), 0.18, Tween.EASE_OUT)


## Eased across, parabola up and over. The island's height is read live because islands bob.
func _arc_point(t: float) -> Vector2:
	var eased: float = ease(t, golem.golem_data.jump_ease)
	var land_y: float = golem.jump_target.get_top_y()
	var x: float = lerpf(_start.x, _landing_x, eased)
	var y: float = lerpf(_start.y, land_y, eased) - _arc_height * 4.0 * t * (1.0 - t)
	return Vector2(x, y)


func _land() -> void:
	golem.is_leaping = false
	golem.velocity = Vector2(0.0, LANDING_SETTLE_SPEED)
	_phase = Phase.RECOVER
	_time_left = golem.golem_data.jump_land_recovery
	golem.update_animation("Idle")
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = golem.create_tween()
	_squash_tween.tween_property(golem.sprite, "scale", BASE_SCALE * Vector2(1.22, 0.76), 0.06)
	_squash_tween.tween_property(golem.sprite, "scale", BASE_SCALE, golem.golem_data.jump_land_recovery) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var data: RockGolemData = golem.golem_data
	if golem.calculate_distance_to_player() <= data.land_shake_range:
		EventBus.camera_shake.emit(data.land_shake_strength, 12.0)


func _tween_scale(target: Vector2, duration: float, ease_type: Tween.EaseType) -> void:
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = golem.create_tween()
	_squash_tween.tween_property(golem.sprite, "scale", target, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(ease_type)
