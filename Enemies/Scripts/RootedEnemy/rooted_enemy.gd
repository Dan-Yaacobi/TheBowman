class_name RootedEnemy extends Enemy
## An enemy rooted on an island: it only falls onto its island and rides it, and knockback
## never moves it. Sleeps (RootedDormantState, hardened) until the player comes close.

@export var gravity: float = 600.0

var rooted_data: RootedEnemyData
## Set by request_wake(); the dormant state wakes on it.
var wake_requested: bool = false
var _away_time: float = 0.0


func extra_ready_functions() -> void:
	rooted_data = stats as RootedEnemyData
	if rooted_data == null:
		push_error("%s needs RootedEnemyData (or a subclass) as its stats" % name)
	animation_player = get_node_or_null("Sprite2D/AnimationPlayer") as AnimationPlayer
	setup_rooted()
	# Deferred so the first state starts after Enemy._ready has finished setting up
	state_machine.Initialize.call_deferred(self)


## Subclass setup, run before the state machine starts.
func setup_rooted() -> void:
	pass


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	velocity.y += gravity * delta
	move_and_slide()


## Called by RootedDormantState when it falls asleep (true) or wakes (false).
func on_dormant_changed(_dormant: bool) -> void:
	pass


## Call every frame while awake: true once the player has stayed out of sleep_range for sleep_delay.
func should_sleep(delta: float) -> bool:
	if calculate_distance_to_player() > rooted_data.sleep_range:
		_away_time += delta
	else:
		_away_time = 0.0
	return _away_time >= rooted_data.sleep_delay


func reset_sleep_timer() -> void:
	_away_time = 0.0


## Combat rifts: its spawn marker activated.
func request_wake() -> void:
	wake_requested = true
