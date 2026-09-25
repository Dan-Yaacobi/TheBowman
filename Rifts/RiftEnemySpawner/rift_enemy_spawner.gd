class_name RiftEnemySpawner extends Node2D
signal enemy_spawned(enemy: Enemy)

@export var enemies: Enemies
@export var enemy_pool: Array[EnemyEntry]
@export var time_between_spawns: float = 1.0

@export_group("Intensity")
## X = main path progress (0-1), Y = intensity (0-1). Built in code if left empty.
@export var main_path_curve: Curve
## Flat intensity for side path chunks before the reward chunk.
@export_range(0.0, 1.0) var side_path_intensity: float = 0.4
## Intensity at the side path reward chunk. Also spawns the full target regardless of what is alive.
@export_range(0.0, 1.0) var terminal_intensity: float = 1.0
## Added to intensity per rift level above 1. Never applied to silent stretches.
@export_range(0.0, 0.2) var level_intensity_bonus: float = 0.05
## Curve values below this are silent: nothing spawns.
@export_range(0.0, 0.5) var silence_threshold: float = 0.05
## The first N chunks of the main path never spawn anything.
@export var safe_chunks: int = 2

@export_group("Pressure")
## Total enemy cost the spawner tries to keep alive, at intensity 0 and 1.
@export var base_pressure: float = 1.0
@export var peak_pressure: float = 4.0
@export var pressure_per_level: float = 0.34
## Hard cap on target pressure. An elite's cost must not exceed this.
@export var max_pressure: int = 6

@export_group("Elites")
## Chance that an eligible spawn trigger starts an elite instead of a normal spawn.
@export_range(0.0, 1.0) var elite_chance: float = 0.5
## Seconds after an elite dies before another can start.
@export var elite_cooldown: float = 45.0
## Max seconds to wait for the field to clear before giving up on a pending elite.
@export var elite_pending_timeout: float = 20.0

@export_group("Spawn Tuning")
## Chance a spawn trigger fires at low intensity (1.0 intensity = always)
@export_range(0.0, 1.0) var min_spawn_chance: float = 0.1

@onready var rift: Rift = $".."

var rift_level: int
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Cost of every enemy that is alive or queued to spawn
var _committed_cost: int = 0
## True while an elite is alive or queued.
var _elite_active: bool = false
## Elite waiting for the field to clear. Blocks all regular spawns.
var _elite_pending: EnemyEntry = null
var _pending_time_left: float = 0.0
var _elite_cooldown_left: float = 0.0


func _ready() -> void:
	if main_path_curve == null:
		main_path_curve = _build_default_main_curve()
	_validate_pool()


func _process(delta: float) -> void:
	if _elite_cooldown_left > 0.0:
		_elite_cooldown_left = maxf(0.0, _elite_cooldown_left - delta)
	if _elite_pending != null:
		_pending_time_left -= delta
		if _pending_time_left <= 0.0:
			_elite_pending = null


func spawn_enemy(level: int, progress: float, chunk_index: int, is_main_path: bool, is_terminal: bool) -> void:
	if _elite_active or _elite_pending != null:
		return
	if is_main_path and chunk_index <= safe_chunks:
		return

	var base_intensity: float = get_base_intensity(progress, is_main_path, is_terminal)
	if base_intensity < silence_threshold:
		return

	var intensity: float = get_intensity(base_intensity, level)
	if randf() > get_spawn_chance(intensity):
		return

	var target: int = get_target_pressure(intensity, level)

	if _elite_cooldown_left <= 0.0 and randf() < elite_chance:
		var elite: EnemyEntry = pick_elite(level, intensity, target)
		if elite != null:
			_start_elite_pending(elite)
			return

	# Reward chunks always spawn the full target, ignoring what is already alive
	var budget: int = target if is_terminal else target - _committed_cost
	if budget <= 0:
		return

	var entries: Array[EnemyEntry] = roll_enemies(budget, level, intensity)
	for entry: EnemyEntry in entries:
		_committed_cost += entry.cost
	_do_spawn(entries)


## Call when the rift is torn down or the player leaves it, before killing enemies.
func reset_elite_state() -> void:
	_elite_pending = null
	_pending_time_left = 0.0


func get_base_intensity(progress: float, is_main_path: bool, is_terminal: bool) -> float:
	if is_terminal:
		return terminal_intensity
	if not is_main_path:
		return side_path_intensity
	return clampf(main_path_curve.sample_baked(clampf(progress, 0.0, 1.0)), 0.0, 1.0)


func get_intensity(base_intensity: float, level: int) -> float:
	var bonus: float = level_intensity_bonus * maxi(level - 1, 0)
	return clampf(base_intensity + bonus, 0.0, 1.0)


func get_spawn_chance(intensity: float) -> float:
	return lerpf(min_spawn_chance, 1.0, intensity)


func get_target_pressure(intensity: float, level: int) -> int:
	var target: float = lerpf(base_pressure, peak_pressure, intensity) + pressure_per_level * level
	return mini(roundi(target), max_pressure)


func _start_elite_pending(entry: EnemyEntry) -> void:
	_elite_pending = entry
	_pending_time_left = elite_pending_timeout
	if _committed_cost <= 0:
		_spawn_pending_elite()


func _spawn_pending_elite() -> void:
	var entry: EnemyEntry = _elite_pending
	_elite_pending = null
	if entry == null:
		return
	_committed_cost += entry.cost
	_elite_active = true
	var entries: Array[EnemyEntry] = [entry]
	_do_spawn(entries)


func _do_spawn(entries: Array[EnemyEntry]) -> void:
	for entry: EnemyEntry in entries:
		if not is_inside_tree():
			return
		var new_enemy: Enemy = PlayerManager.player.spawn_handler.spawn_from_zone(
			entry.get_factory(), entry.spawn_zone
		)
		if new_enemy == null:
			_release(entry.cost, entry.is_elite)
			continue
		new_enemy.tree_exited.connect(_release.bind(entry.cost, entry.is_elite), CONNECT_ONE_SHOT)
		enemy_spawned.emit(new_enemy)
		await get_tree().create_timer(time_between_spawns, false).timeout


func _release(cost: int, was_elite: bool) -> void:
	_committed_cost -= cost
	if was_elite:
		_elite_active = false
		_elite_cooldown_left = elite_cooldown
	elif _elite_pending != null and _committed_cost <= 0:
		_spawn_pending_elite()


func get_eligible_entries(level: int, intensity: float, want_elite: bool) -> Array[EnemyEntry]:
	return enemy_pool.filter(
		func(e: EnemyEntry) -> bool: return e.is_elite == want_elite and e.is_eligible(level, intensity)
	)


func pick_elite(level: int, intensity: float, target: int) -> EnemyEntry:
	var candidates: Array[EnemyEntry] = get_eligible_entries(level, intensity, true).filter(
		func(e: EnemyEntry) -> bool: return e.cost <= target
	)
	if candidates.is_empty():
		return null
	var weights: Array = candidates.map(func(e: EnemyEntry) -> float: return e.base_weight)
	return candidates[rng.rand_weighted(weights)]


func roll_enemies(budget: int, level: int, intensity: float) -> Array[EnemyEntry]:
	var result: Array[EnemyEntry] = []
	var remaining: int = budget
	var pool: Array[EnemyEntry] = get_eligible_entries(level, intensity, false)
	while remaining > 0:
		var affordable: Array[EnemyEntry] = pool.filter(
			func(e: EnemyEntry) -> bool: return e.cost <= remaining
		)
		if affordable.is_empty():
			break
		var weights: Array = affordable.map(
			func(e: EnemyEntry) -> float: return e.base_weight
		)
		var rolled: EnemyEntry = affordable[rng.rand_weighted(weights)]
		result.append(rolled)
		remaining -= rolled.cost
	return result


func _validate_pool() -> void:
	for entry: EnemyEntry in enemy_pool:
		if entry.is_elite and entry.cost > max_pressure:
			push_warning("Elite %s costs %d, above max_pressure %d: it can never spawn." % [entry.resource_path, entry.cost, max_pressure])


func _build_default_main_curve() -> Curve:
	# Same shape as the old sin() formula: quiet start, peak mid-rift, easing off
	var curve: Curve = Curve.new()
	for i in range(11):
		var x: float = i / 10.0
		curve.add_point(Vector2(x, clampf(sin(x * PI * 1.2 - 0.2), 0.0, 1.0)))
	return curve
