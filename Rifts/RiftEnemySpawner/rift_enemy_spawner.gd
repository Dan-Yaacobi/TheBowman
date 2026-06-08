class_name RiftEnemySpawner extends Node2D

signal enemy_spawned(enemy: Enemy)

@export var enemies: Enemies
@export var enemy_pool: Array[EnemyEntry]

@onready var rift: Rift = $".."

const SIDE_PATH_INTENSITY: float = 0.4

var rift_level: int
var rng = RandomNumberGenerator.new()

func get_spawn_intensity(progress: float) -> float:
	# peaks at progress 0.6, returns 0.0 -> 1.0
	return sin(progress * PI * 1.2 - 0.2)

func get_spawn_chance(intensity: float) -> float:
	return lerpf(0.1, 1.0, intensity)

func get_spawn_count(intensity: float, level: int) -> int:
	var base: float = lerpf(1.0, 4.0, intensity)
	return mini(roundi(base) + int(level / 3), 6)
	
func spawn_enemy(level: int, progress: float, is_main_path: bool, is_terminal: bool) -> void:	#var spider_factory: Callable = enemies.get_black_spider_factory()
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
	var factories: Array[Callable] = roll_enemies(count, level)
	for factory in factories:
		var new_enemy: Enemy = PlayerManager.player.spawn_handler.spawn_from_any(factory)
		if new_enemy != null:
			enemy_spawned.emit(new_enemy)

func get_eligible_entries(level: int) -> Array[EnemyEntry]:
	return enemy_pool.filter(func(e: EnemyEntry) -> bool: return level >= e.min_level)

func get_weight(entry: EnemyEntry, level: int) -> float:
	return maxf(0.0, entry.base_weight + entry.weight_curve * level)

func roll_enemies(budget: int, level: int) -> Array[Callable]:
	var result: Array[Callable] = []
	var remaining: int = budget
	
	while remaining > 0:
		var eligible: Array[EnemyEntry] = get_eligible_entries(level).filter(
			func(e: EnemyEntry) -> bool: return e.cost <= remaining
		)
		if eligible.is_empty():
			break
		
		var weights = eligible.map(
			func(e: EnemyEntry) -> float: return get_weight(e, level)
		)
		var rolled: EnemyEntry = eligible[rng.rand_weighted(weights)]
		result.append(rolled.get_factory())
		remaining -= rolled.cost
	
	return result
