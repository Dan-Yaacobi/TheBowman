class_name RockGolemJumpState extends EnemyState
## A solid rock hopping: it never squashes or stretches.
## Stands still a moment, then follows an arc planned at take-off from start to landing,
## speeding up into a slam on the island (camera shake, the island sinks under it), and
## stands still for a moment. Scripted, not physics, so it lands exactly.

@export var land_state: EnemyState
## Small downward speed on landing so the body settles onto the island
const LANDING_SETTLE_SPEED: float = 40.0
## Samples along the arc for even speed (arc-length table)
const ARC_SAMPLES: int = 32

enum Phase { WINDUP, AIR, RECOVER }

var golem: RockGolem
var _phase: Phase = Phase.WINDUP
var _time_left: float = 0.0
var _air_time: float = 0.0
var _duration: float = 1.0
var _start: Vector2 = Vector2.ZERO
var _control: Vector2 = Vector2.ZERO
var _landing_x: float = 0.0
## Arc length travelled at each sample t = i / ARC_SAMPLES, normalised to 0-1
var _arc_lengths: PackedFloat32Array = PackedFloat32Array()
var _arc_total: float = 0.0


func init() -> void:
	golem = enemy as RockGolem


func Enter() -> void:
	golem.move_x = 0.0
	_phase = Phase.WINDUP
	_time_left = golem.golem_data.jump_windup
	golem.update_animation("Idle")
	if golem.jump_target:
		golem.face_x(golem.jump_target.get_top_center().x)


func Exit() -> void:
	golem.is_leaping = false
	golem.move_x = 0.0
	golem.jump_cooldown_left = golem.golem_data.jump_cooldown


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
			_air_time = minf(_air_time + delta, _duration)
			var travelled: float = pow(_air_time / _duration, golem.golem_data.jump_ease_power)
			golem.global_position = _bezier(_t_at_length(travelled))
			if _air_time >= _duration:
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


func _launch() -> void:
	var data: RockGolemData = golem.golem_data
	var landing: Vector2 = golem.get_landing_point(golem.jump_target)
	_start = golem.global_position
	_landing_x = landing.x
	# Quadratic bezier: the control point sits above the middle at twice the wanted
	# peak height, so the curve peaks `arc` above the higher end
	var distance: float = _start.distance_to(landing)
	var arc: float = clampf(distance * data.jump_arc_ratio, data.jump_arc_min, data.jump_arc_max)
	var peak_y: float = minf(_start.y, landing.y) - arc
	var mid_y: float = (_start.y + landing.y) * 0.5
	_control = Vector2((_start.x + landing.x) * 0.5, mid_y + 2.0 * (peak_y - mid_y))
	_build_arc_lengths(landing)
	_duration = clampf(_arc_total / data.jump_speed, data.jump_min_time, data.jump_max_time)
	_air_time = 0.0
	_phase = Phase.AIR
	golem.is_leaping = true
	golem.velocity = Vector2.ZERO
	golem.knockback_velocity = Vector2.ZERO
	golem.update_animation("Walk")


func _build_arc_lengths(landing: Vector2) -> void:
	_arc_lengths.resize(ARC_SAMPLES + 1)
	_arc_lengths[0] = 0.0
	var previous: Vector2 = _start
	var total: float = 0.0
	for i: int in range(1, ARC_SAMPLES + 1):
		var point: Vector2 = _bezier_to(float(i) / ARC_SAMPLES, landing)
		total += previous.distance_to(point)
		_arc_lengths[i] = total
		previous = point
	_arc_total = maxf(total, 0.001)
	for i: int in range(ARC_SAMPLES + 1):
		_arc_lengths[i] /= _arc_total


## Curve parameter t where the given share (0-1) of the arc length has been travelled.
func _t_at_length(share: float) -> float:
	for i: int in range(1, ARC_SAMPLES + 1):
		if _arc_lengths[i] >= share:
			var a: float = _arc_lengths[i - 1]
			var span: float = maxf(_arc_lengths[i] - a, 0.0001)
			return (float(i - 1) + (share - a) / span) / ARC_SAMPLES
	return 1.0


## Point on the arc. The landing height is read live because islands bob.
func _bezier(t: float) -> Vector2:
	return _bezier_to(t, Vector2(_landing_x, golem.jump_target.get_top_y()))


func _bezier_to(t: float, landing: Vector2) -> Vector2:
	var u: float = 1.0 - t
	return u * u * _start + 2.0 * u * t * _control + t * t * landing


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
