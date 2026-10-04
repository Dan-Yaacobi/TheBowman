class_name MovingTargetGoal extends ChallengeGoal

@export var target_scene: PackedScene
@export var targets_required: int = 5
@export var time_limit: float = 45.0
## Each target is this many percent faster than the base speed, per target already hit.
@export var speed_per_hit: float = 20.0
## Random +/- percent added to each target's speed.
@export var speed_variance: float = 10.0
## Path from the event root to the node holding the TargetRoute children.

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
	var event: MovingTargetEvent = challenge as MovingTargetEvent
	if event == null:
		push_warning("TargetPracticeGoal must run in a MovingTargetEvent.")
		failed.emit("Wrong event")
		return

	_routes = event.get_routes()
	if _routes.is_empty():
		push_warning("TargetPracticeGoal: no TargetRoute nodes under TargetRoutes.")
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

func stop() -> void:
	_done = true
	if is_instance_valid(_current):
		_current.queue_free()
	_current = null

func get_progress_text() -> String:
	return "%d / %d   %ds" % [_hits, targets_required, ceili(_time_left)]

func _spawn_next() -> void:
	var route: TargetRoute = _routes[_next_route_index()]
	var target: FlyingTarget = target_scene.instantiate()

	if randf() < 0.5:
		target.start_position = route.get_start()
		target.end_position = route.get_end()
	else:
		target.start_position = route.get_end()
		target.end_position = route.get_start()

	var speed_percent: float = speed_per_hit * _hits + randf_range(-speed_variance, speed_variance)
	target.ready.connect(target.scale_speed.bind(speed_percent), CONNECT_ONE_SHOT)
	target.target_hit.connect(_on_target_hit)

	_current = target
	EventBus.summon_effect.emit(target)

func _on_target_hit(target: FlyingTarget) -> void:
	if _done:
		return
	_hits += 1
	target.queue_free()
	_current = null
	if _hits >= targets_required:
		completed.emit()
	else:
		_spawn_next()

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
