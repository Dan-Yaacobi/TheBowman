class_name ChallengeStoneEvent extends Event

signal challenge_started
signal challenge_finished(success: bool)

@export var challenge_pool: Array[ChallengeDef] = []
@onready var hud: ChallengeHUD = $ChallengeHUD
@onready var shrine: ChallengeShrine = $Islands/Island/ChallengeShrine
@onready var spawner: ChallengeSpawner = $ChallengeSpawner
@onready var exit_portal: EventPortal = $EventPortal
@onready var falling_death: Node2D = $FallingDeath
@export var curse_offer_count: int = 3

@onready var curse_picker: CursePicker = $CursePicker

var offered_curses: Array[ChallengeCurse] = []
var taken_curse_weight: int = 0

var challenge: ChallengeDef
var goal: ChallengeGoal
var active_modifiers: Array[ChallengeModifier] = []
var is_running: bool = false
var is_finished: bool = false

func _ready() -> void:
	if challenge_pool.is_empty():
		push_warning("ChallengeStoneEvent has an empty challenge_pool.")
	shrine.interacted.connect(_on_shrine_interacted)
	curse_picker.confirmed.connect(start_challenge)
	shrine.interaction_closed.connect(curse_picker.close)
	curse_picker.cancelled.connect(shrine.end_interaction)
	falling_death.player_fell.connect(_on_player_fell)
	hud.hide()

func _process(delta: float) -> void:
	if is_running:
		goal.tick(delta)
		if is_running:
			hud.set_progress(goal.get_progress_text())
			
func start_challenge(curses: Array[ChallengeCurse]) -> void:
	if is_running or is_finished or challenge == null:
		return
	is_running = true
	exit_portal.set_locked(true)
	shrine.action_taken = true
	shrine.end_interaction()
	
	taken_curse_weight = 0
	for curse: ChallengeCurse in curses:
		taken_curse_weight += curse.reward_weight
		
	goal = challenge.goal.duplicate(true)
	goal.completed.connect(_finish.bind(true), CONNECT_ONE_SHOT)
	goal.failed.connect(_on_goal_failed, CONNECT_ONE_SHOT)

	active_modifiers.clear()
	for modifier: ChallengeModifier in challenge.modifiers:
		active_modifiers.append(modifier.duplicate(true))
	for curse: ChallengeModifier in curses:
		active_modifiers.append(curse.duplicate(true))
	for modifier: ChallengeModifier in active_modifiers:
		modifier.apply(self)
	spawner.enemy_created.connect(_on_enemy_created)
	EventBus.enemy_died.connect(_on_enemy_died)
	if goal.uses_continuous_spawn():
		var level: int = current_rift_level()
		spawner.start_continuous(challenge.get_pool_for_level(level), challenge.get_spawn_interval(level), challenge.get_max_alive(level))
	goal.start(self)
	challenge_started.emit()
	hud.show_challenge(challenge)
	hud.set_progress(goal.get_progress_text())
	
func _on_player_fell() -> void:
	if is_running:
		_finish(false)

func _on_enemy_died(enemy: Enemy) -> void:
	if is_running:
		goal.on_enemy_killed(enemy)

func _on_goal_failed(_reason: String) -> void:
	_finish(false)

func _finish(success: bool) -> void:
	if not is_running:
		return
	is_running = false
	is_finished = true
	exit_portal.set_locked(false)
	if spawner.enemy_created.is_connected(_on_enemy_created):
		spawner.enemy_created.disconnect(_on_enemy_created)
		
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)
	spawner.stop()
	goal.stop()
	for modifier: ChallengeModifier in active_modifiers:
		modifier.remove(self)
	active_modifiers.clear()

	var world: GameWorld = get_parent() as GameWorld
	if world:
		world.kill_all_enemies()

	if success:
		spawn_rewards(shrine.global_position, taken_curse_weight, challenge.rewards)
	hud.show_result(success)
	challenge_finished.emit(success)
	report_finished(success)

func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	if challenge and not challenge.display_name.is_empty():
		return challenge.display_name
	return ""

func on_event_exited() -> void:
	if is_running:
		_finish(false)

func _on_shrine_interacted() -> void:
	if is_running or is_finished or challenge_pool.is_empty():
		return
	if challenge == null:
		challenge = challenge_pool.pick_random()
		_roll_curse_offer()
	curse_picker.open(challenge, offered_curses)

func _roll_curse_offer() -> void:
	var pool: Array[ChallengeCurse] = challenge.curse_pool.duplicate()
	pool.shuffle()
	offered_curses.clear()
	for i: int in mini(curse_offer_count, pool.size()):
		offered_curses.append(pool[i])

func _on_enemy_created(enemy: Enemy) -> void:
	if not is_running:
		return
	for modifier: ChallengeModifier in active_modifiers:
		modifier.on_enemy_spawned(self, enemy)
