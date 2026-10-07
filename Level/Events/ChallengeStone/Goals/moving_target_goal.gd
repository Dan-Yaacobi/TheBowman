class_name MovingTargetGoal extends ChallengeGoal

@export var target_entry: EnemyEntry
@export var targets_required: int = 5
@export var time_limit: float = 45.0
## Each target is this many percent faster than the base speed, per target already hit.
@export var speed_per_hit: float = 20.0
## Random +/- percent added to each target's speed.
@export var speed_variance: float = 10.0

var _challenge: MovingTargetEvent  # new
var _routes: Array[TargetRoute] = []
var _route_bag: Array[int] = []
var _last_route: int = -1
var _hits: int = 0
var _time_left: float = 0.0
var _current: FlyingTarget = null
var _done: bool = false

func uses_continuous_spawn() -> bool:
	return false

func start(challenge: ChallengeStoneEvent) -> void:
	_challenge = challenge as MovingTargetEvent
	if _challenge == null:
		push_warning("MovingTargetGoal must run in a MovingTargetEvent.")
		failed.emit("Wrong event")
		return

	_routes = _challenge.get_routes()
	if _routes.is_empty():
		push_warning("MovingTargetGoal: no TargetRoute nodes under TargetRoutes.")
		failed.emit("No routes")
		return

	_hits = 0
	_time_left = time_limit
	_route_bag.clear()
	_last_route = -1
	_done = false
	_spawn_next()

func tick(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		failed.emit("Out of time")

# new: hits are counted from enemy deaths, replacing target_hit
func on_enemy_killed(enemy: Enemy) -> void:
	if _done or enemy != _current:
		return
	_hits += 1
	_current = null
	if _hits >= targets_required:
		completed.emit()
	else:
		_spawn_next()

func stop() -> void:
	_done = true
	if is_instance_valid(_current):
		_current.queue_free()
	_current = null

func get_progress_text() -> String:
	return "%d / %d   %ds" % [_hits, targets_required, ceili(_time_left)]

func _spawn_next() -> void:
	var route: TargetRoute = _routes[_next_route_index()]
	var from: Vector2 = route.get_start()
	var to: Vector2 = route.get_end()
	if randf() < 0.5:
		from = route.get_end()
		to = route.get_start()

	var target: FlyingTarget = _challenge.spawner.spawn_at(target_entry, from) as FlyingTarget
	if target == null:
		push_warning("MovingTargetGoal: target_entry's scene is not a FlyingTarget.")
		failed.emit("Bad target")
		return

	target.start_position = from
	target.end_position = to
	var speed_percent: float = speed_per_hit * _hits + randf_range(-speed_variance, speed_variance)
	target.stats.move_speed.add_buff(get_instance_id(), speed_percent / 100.0, Stat.buff_type.MULTIPLICATIVE)
	_current = target

## Shuffled bag of route indices: no repeats until every route has been used, never the same route twice in a row.
func _next_route_index() -> int:
	if _route_bag.is_empty():
		for i: int in _routes.size():
			_route_bag.append(i)
		_route_bag.shuffle()
		if _route_bag.size() > 1 and _route_bag.back() == _last_route:
			var swap: int = _route_bag[0]
			_route_bag[0] = _route_bag.back()
			_route_bag[-1] = swap
	var index: int = _route_bag.pop_back()
	_last_route = index
	return index
