class_name RockGolemJumpState extends EnemyState
## A solid rock hopping: it never squashes or stretches.
## Slow to start and stop, sudden in between: rumbles in place, then a quick low hop under
## heavy gravity, slams into the island (camera shake, the island sinks under it) and
## stands still for a moment. The arc is scripted (not physics) so it lands exactly.

@export var land_state: EnemyState
## Small downward speed on landing so the body settles onto the island
const LANDING_SETTLE_SPEED: float = 40.0
## How often the rumble changes side (seconds)
const RUMBLE_STEP: float = 0.05

enum Phase { WINDUP, AIR, RECOVER }

var golem: RockGolem
var _phase: Phase = Phase.WINDUP
var _time_left: float = 0.0
var _rumble_left: float = 0.0
var _rumble_side: float = 1.0
var _air_time: float = 0.0
var _rise_time: float = 0.0
var _fall_time: float = 0.0
var _start: Vector2 = Vector2.ZERO
var _landing_x: float = 0.0
var _peak_y: float = 0.0


func init() -> void:
	golem = enemy as RockGolem


func Enter() -> void:
	golem.move_x = 0.0
	_phase = Phase.WINDUP
	_time_left = golem.golem_data.jump_windup
	_rumble_left = 0.0
	golem.update_animation("Idle")
	if golem.jump_target:
		golem.face_x(golem.jump_target.get_top_center().x)


func Exit() -> void:
	golem.is_leaping = false
	golem.move_x = 0.0
	golem.sprite.position = Vector2.ZERO
	golem.jump_cooldown_left = golem.golem_data.jump_cooldown


func Physics(delta: float) -> EnemyState:
	match _phase:
		Phase.WINDUP:
			if not _target_valid():
				return land_state
			_rumble(delta)
			_time_left -= delta
			if _time_left <= 0.0:
				_launch()
		Phase.AIR:
			if not _target_valid():
				# Island gone mid-air: drop and let gravity decide
				golem.is_leaping = false
				return land_state
			_air_time = minf(_air_time + delta, _rise_time + _fall_time)
			golem.global_position = _arc_point(_air_time)
			if _air_time >= _rise_time + _fall_time:
				_land()
		Phase.RECOVER:
			# Ride the island while it sinks and springs back, so it can't slip through it
			# (islands only block from above)
			if _target_valid():
				golem.global_position.y = golem.jump_target.get_top_y()
			_time_left -= delta
			if _time_left <= 0.0 and not (_target_valid() and golem.jump_target.is_dipping()):
				return land_state
	return null


func _target_valid() -> bool:
	return golem.jump_target != null and is_instance_valid(golem.jump_target) \
		and golem.jump_target.is_solid()


## Shakes side to side in place, like a boulder about to come loose.
func _rumble(delta: float) -> void:
	_rumble_left -= delta
	if _rumble_left <= 0.0:
		_rumble_left = RUMBLE_STEP
		_rumble_side = -_rumble_side
		golem.sprite.position.x = _rumble_side * golem.golem_data.jump_rumble


func _launch() -> void:
	var data: RockGolemData = golem.golem_data
	var landing: Vector2 = golem.get_landing_point(golem.jump_target)
	golem.sprite.position = Vector2.ZERO
	_start = golem.global_position
	_landing_x = landing.x
	var arc: float = data.jump_arc_height + data.jump_arc_per_distance * absf(landing.x - _start.x)
	_peak_y = minf(_start.y, landing.y) - arc
	# Real projectile timing: t = sqrt(2h / g), with the heavier pull on the way down
	_rise_time = sqrt(2.0 * (_start.y - _peak_y) / data.jump_gravity)
	_fall_time = sqrt(2.0 * (landing.y - _peak_y) / (data.jump_gravity * data.jump_fall_gravity_multiplier))
	_air_time = 0.0
	_phase = Phase.AIR
	golem.is_leaping = true
	golem.velocity = Vector2.ZERO
	golem.knockback_velocity = Vector2.ZERO
	golem.update_animation("Walk")


## Constant speed across; a parabola up into the peak, then a harder parabola down.
## The island's height is read live because islands bob.
func _arc_point(t: float) -> Vector2:
	var total: float = _rise_time + _fall_time
	var x: float = lerpf(_start.x, _landing_x, t / total)
	var y: float
	if t < _rise_time:
		var left: float = (_rise_time - t) / _rise_time
		y = lerpf(_peak_y, _start.y, left * left)
	else:
		var fallen: float = (t - _rise_time) / _fall_time
		y = lerpf(_peak_y, golem.jump_target.get_top_y(), fallen * fallen)
	return Vector2(x, y)


func _land() -> void:
	var data: RockGolemData = golem.golem_data
	# Stays scripted (is_leaping) through the recovery; Exit hands it back to physics
	golem.velocity = Vector2(0.0, LANDING_SETTLE_SPEED)
	_phase = Phase.RECOVER
	_time_left = data.jump_land_recovery
	golem.update_animation("Idle")
	golem.jump_target.dip(data.land_island_dip)
	if golem.calculate_distance_to_player() <= data.land_shake_range:
		EventBus.camera_shake.emit(data.land_shake_strength, 12.0)
