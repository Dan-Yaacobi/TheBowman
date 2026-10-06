class_name ChallengeSpawner extends Node

@export var time_between_enemy_spawns: float = 0.4

signal enemy_created(enemy: Enemy)

var alive_count: int = 0
var is_spawning: bool = false

var _pool: Array[EnemyEntry] = []
var _interval: float = 1.5
var _max_alive: int = 5
var _continuous: bool = false
var _time_to_next: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func start_continuous(pool: Array[EnemyEntry], interval: float, max_alive: int) -> void:
	_pool = pool
	_interval = interval
	_max_alive = max_alive
	_time_to_next = 0.0
	_continuous = not pool.is_empty()

func stop() -> void:
	_continuous = false
	is_spawning = false

func _process(delta: float) -> void:
	if not _continuous:
		return
	_time_to_next -= delta
	if _time_to_next <= 0.0 and alive_count < _max_alive:
		_time_to_next = _interval
		_spawn(_pick_weighted())

func spawn_wave(entries: Array[EnemyEntry]) -> void:
	is_spawning = true
	for entry: EnemyEntry in entries:
		if not is_inside_tree() or not is_spawning:
			return
		_spawn(entry)
		await get_tree().create_timer(time_between_enemy_spawns, false).timeout
	is_spawning = false

func _spawn(entry: EnemyEntry) -> void:
	var factory: Callable = entry.get_factory()
	var cursed_factory: Callable = func() -> Enemy:
		var created: Enemy = factory.call()
		enemy_created.emit(created)
		return created
	var enemy: Enemy = PlayerManager.player.spawn_handler.spawn_from_zone(
		cursed_factory, entry.spawn_zone
	)
	if enemy == null:
		return
	alive_count += 1
	enemy.tree_exited.connect(_on_enemy_gone, CONNECT_ONE_SHOT)
	EventBus.enemy_summoned.emit(enemy)
	
func _on_enemy_gone() -> void:
	alive_count -= 1

func _pick_weighted() -> EnemyEntry:
	var weights: Array = _pool.map(func(e: EnemyEntry) -> float: return e.base_weight)
	return _pool[_rng.rand_weighted(weights)]
