class_name RiftEnemySpawner extends Node2D
## Spawns rift enemies by a hand-made SpawnPlan. Each rift picks a random plan from its biome's
## pool. Entering a new chunk (main or side path, the player can't tell them apart) tops the
## enemies alive up to the plan's target for the current progress, one every time_between_spawns.
## Already fighting: nothing extra. Kiting one enemy ahead: the rest of the target joins in.

signal enemy_spawned(enemy: Enemy)

@export var enemy_pool: Array[EnemyEntry]
@export var time_between_spawns: float = 1.0

@export_group("Spawn Plans")
## Plan pools by biome (dirt, snow, hell). A rift picks one plan at random from its biome's pool.
@export var early_plans: Array[SpawnPlan] = []
@export var mid_plans: Array[SpawnPlan] = []
@export var late_plans: Array[SpawnPlan] = []

@export_group("Limits")
## The guarded reward chunk at the end of a side path spawns the current target plus this many,
## whatever is already alive.
@export var reward_chunk_extra: int = 1
## Safety cap: never more spawned enemies alive than this.
@export var max_alive: int = 6
## Entries with at least this cost count as heavy (birds, golems): at most one per top-up.
@export var heavy_cost: int = 3

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var is_suspended: bool = false
## Rolled but not spawned yet (the 1s gap between spawns)
var _queued: int = 0
## Spawned by this spawner; counted while valid and not dead (a death animation doesn't count)
var _spawned: Array[Enemy] = []
var _plan: SpawnPlan
var _plan_level: int = -1


func spawn_enemy(level: int, progress: float, is_reward_chunk: bool) -> void:
	if is_suspended:
		return
	if level != _plan_level:
		_plan_level = level
		_plan = _pick_plan(level)
	if _plan == null:
		return
	var target: int = _plan.target_at(progress)
	var alive: int = get_alive_count()
	var count: int = target + reward_chunk_extra if is_reward_chunk else target - alive
	count = mini(count, max_alive - alive)
	if count <= 0:
		return
	var entries: Array[EnemyEntry] = roll_enemies(count, level)
	_queued += entries.size()
	_do_spawn(entries)


func get_plan() -> SpawnPlan:
	return _plan


## Spawned enemies still alive, plus any still waiting to spawn.
func get_alive_count() -> int:
	var alive: Array[Enemy] = []
	for enemy: Enemy in _spawned:
		if is_instance_valid(enemy) and not enemy.is_dead:
			alive.append(enemy)
	_spawned = alive
	return _queued + alive.size()


func _pick_plan(level: int) -> SpawnPlan:
	var pools: Array = [early_plans, mid_plans, late_plans]
	var pool: Array[SpawnPlan] = pools[clampi(CustomVariables.biome_index(level), 0, pools.size() - 1)]
	if pool.is_empty():
		push_warning("RiftEnemySpawner: no spawn plans for rift level %d" % level)
		return null
	return pool[rng.randi_range(0, pool.size() - 1)]


func _do_spawn(entries: Array[EnemyEntry]) -> void:
	for i: int in entries.size():
		if not is_inside_tree():
			return
		if is_suspended:
			_queued -= entries.size() - i
			return
		var entry: EnemyEntry = entries[i]
		var new_enemy: Enemy = PlayerManager.player.spawn_handler.spawn_from_zone(
			entry.get_factory(), entry.spawn_zone
		)
		_queued -= 1
		if new_enemy:
			_spawned.append(new_enemy)
			enemy_spawned.emit(new_enemy)
		if i < entries.size() - 1:
			await get_tree().create_timer(time_between_spawns, false).timeout


## count enemies for this rift level, weighted, with at most one heavy.
func roll_enemies(count: int, level: int) -> Array[EnemyEntry]:
	var result: Array[EnemyEntry] = []
	var pool: Array[EnemyEntry] = []
	for entry: EnemyEntry in enemy_pool:
		if entry.appears_at(level):
			pool.append(entry)
	var heavy_taken: bool = false
	for i: int in count:
		var choices: Array[EnemyEntry] = []
		for entry: EnemyEntry in pool:
			if not (heavy_taken and entry.cost >= heavy_cost):
				choices.append(entry)
		if choices.is_empty():
			break
		var weights: PackedFloat32Array = PackedFloat32Array()
		for entry: EnemyEntry in choices:
			weights.append(entry.base_weight)
		var rolled: EnemyEntry = choices[rng.rand_weighted(weights)]
		heavy_taken = heavy_taken or rolled.cost >= heavy_cost
		result.append(rolled)
	return result
