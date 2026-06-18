class_name RiftEnemySpawner extends Node2D

signal enemy_spawned(enemy: Enemy)

@export var enemies: Enemies
@export var enemy_pool: Array[EnemyEntry]
@onready var rift: Rift = $".."

const SIDE_PATH_INTENSITY: float = 0.4

var rift_level: int
var rng := RandomNumberGenerator.new()
var _active_enemies: Array[Enemy] = []
var _pending_spawns: Array[Dictionary] = []


func get_spawn_intensity(progress: float) -> float:
	return sin(progress * PI * 1.2 - 0.2)


func get_spawn_chance(intensity: float) -> float:
	return lerpf(0.1, 1.0, intensity)


func get_spawn_count(intensity: float, level: int) -> int:
	var count_intensity: float = maxf(0.0, (intensity - 0.4) / 0.6)
	var base: float = lerpf(1.0, 4.0, count_intensity)
	@warning_ignore("integer_division")
	return mini(roundi(base) + level / 3, 6)


func spawn_enemy(level: int, progress: float, is_main_path: bool, is_terminal: bool) -> void:
	var intensity: float
	if is_terminal:
		intensity = 1.0
	elif is_main_path:
		intensity = get_spawn_intensity(progress)
	else:
		intensity = SIDE_PATH_INTENSITY

	var chance: float = get_spawn_chance(intensity)
	if randf() > chance:
		return

	var count: int = get_spawn_count(intensity, level)
	var entries: Array[EnemyEntry] = roll_enemies(count, level)

	if _active_enemies.is_empty():
		_do_spawn(entries)
	else:
		_pending_spawns.append({ "entries": entries })


func _do_spawn(entries: Array[EnemyEntry]) -> void:
	for entry in entries:
		var new_enemy: Enemy = PlayerManager.player.spawn_handler.spawn_from_zone(
			entry.get_factory(), entry.spawn_zone
		)
		if new_enemy == null:
			continue
		_active_enemies.append(new_enemy)
		new_enemy.tree_exited.connect(_on_enemy_removed.bind(new_enemy), CONNECT_ONE_SHOT)
		enemy_spawned.emit(new_enemy)
		await get_tree().create_timer(0.6).timeout


func _on_enemy_removed(enemy: Enemy) -> void:
	_active_enemies.erase(enemy)
	if _active_enemies.is_empty() and not _pending_spawns.is_empty():
		var next: Dictionary = _pending_spawns.pop_front()
		_do_spawn(next["entries"])


func get_eligible_entries(level: int) -> Array[EnemyEntry]:
	return enemy_pool.filter(func(e: EnemyEntry) -> bool: return level >= e.min_level)


func get_weight(entry: EnemyEntry, level: int) -> float:
	return maxf(0.0, entry.base_weight + entry.weight_curve * level)


func roll_enemies(budget: int, level: int) -> Array[EnemyEntry]:
	var result: Array[EnemyEntry] = []
	var remaining: int = budget
	while remaining > 0:
		var eligible: Array[EnemyEntry] = get_eligible_entries(level).filter(
			func(e: EnemyEntry) -> bool: return e.cost <= remaining
		)
		if eligible.is_empty():
			break
		var weights: Array = eligible.map(
			func(e: EnemyEntry) -> float: return get_weight(e, level)
		)
		var rolled: EnemyEntry = eligible[rng.rand_weighted(weights)]
		result.append(rolled)
		remaining -= rolled.cost
	return result
