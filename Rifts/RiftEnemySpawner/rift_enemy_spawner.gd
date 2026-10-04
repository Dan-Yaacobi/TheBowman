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
## Hard cap on target pressure.
@export var max_pressure: int = 6

@export_group("Spawn Tuning")
## Chance a spawn trigger fires at low intensity (1.0 intensity = always)
@export_range(0.0, 1.0) var min_spawn_chance: float = 0.1

@onready var rift: Rift = $".."

var rift_level: int
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Cost of every enemy that is alive or queued to spawn
var _committed_cost: int = 0

var is_suspended: bool = false

func _ready() -> void:
	if main_path_curve == null:
		main_path_curve = _build_default_main_curve()


func spawn_enemy(level: int, progress: float, chunk_index: int, is_main_path: bool, is_terminal: bool) -> void:
	if is_suspended:
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

	# Reward chunks always spawn the full target, ignoring what is already alive
	var budget: int = target if is_terminal else target - _committed_cost
	if budget <= 0:
		return

	var entries: Array[EnemyEntry] = roll_enemies(budget, level, intensity)
	for entry: EnemyEntry in entries:
		_committed_cost += entry.cost
	_do_spawn(entries)


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


func _do_spawn(entries: Array[EnemyEntry]) -> void:
	for i: int in entries.size():
		var entry: EnemyEntry = entries[i]
		if not is_inside_tree():
			return
		if is_suspended:
			for skipped: EnemyEntry in entries.slice(i):
				_release(skipped.cost)
			return
		var new_enemy: Enemy = PlayerManager.player.spawn_handler.spawn_from_zone(
			entry.get_factory(), entry.spawn_zone
		)
		if new_enemy == null:
			_release(entry.cost)
			continue
		new_enemy.tree_exited.connect(_release.bind(entry.cost), CONNECT_ONE_SHOT)
		enemy_spawned.emit(new_enemy)
		await get_tree().create_timer(time_between_spawns, false).timeout

func _release(cost: int) -> void:
	_committed_cost -= cost


func get_eligible_entries(level: int, intensity: float) -> Array[EnemyEntry]:
	return enemy_pool.filter(
		func(e: EnemyEntry) -> bool: return e.is_eligible(level, intensity)
	)


func roll_enemies(budget: int, level: int, intensity: float) -> Array[EnemyEntry]:
	var result: Array[EnemyEntry] = []
	var remaining: int = budget
	var pool: Array[EnemyEntry] = get_eligible_entries(level, intensity)
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


func _build_default_main_curve() -> Curve:
	# Same shape as the old sin() formula: quiet start, peak mid-rift, easing off
	var curve: Curve = Curve.new()
	for i in range(11):
		var x: float = i / 10.0
		curve.add_point(Vector2(x, clampf(sin(x * PI * 1.2 - 0.2), 0.0, 1.0)))
	return curve
