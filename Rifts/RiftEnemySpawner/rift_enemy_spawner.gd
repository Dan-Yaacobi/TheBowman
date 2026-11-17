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
## The guarded reward chunk at the end of a side path tops up to the current target plus this many.
@export var reward_chunk_extra: int = 1
## Safety cap: never more spawned enemies alive than this.
@export var max_alive: int = 6
## Entries with at least this cost count as heavy (birds, golems): at most one per top-up.
@export var heavy_cost: int = 3

@export_group("Debug")
## Debug builds only: a corner readout of the plan, target and enemies alive.
@export var show_debug_label: bool = true

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var is_suspended: bool = false
## Rolled but not spawned yet (the 1s gap between spawns)
var _queued: int = 0
## Spawned by this spawner (or split from one); counted while valid and not dead
## (a death animation doesn't count)
var _spawned: Array[Enemy] = []
## Instance ids of everything this spawner owns, kept after death so split children can be claimed
var _owned_ids: Dictionary[int, bool] = {}
var _last_progress: float = 0.0
var _last_target: int = 0
var _debug_label: Label
var _debug_refresh: float = 0.0


func _ready() -> void:
	EventBus.enemy_summoned.connect(_on_event_bus_enemy_summoned)
	if show_debug_label and OS.is_debug_build():
		_build_debug_label()


func _process(delta: float) -> void:
	if _debug_label == null:
		return
	_debug_refresh -= delta
	if _debug_refresh <= 0.0:
		_debug_refresh = 0.25
		_update_debug_label()
var _plan: SpawnPlan
var _plan_level: int = -1


func spawn_enemy(level: int, progress: float, is_reward_chunk: bool) -> void:
	if is_suspended:
		return
	if level != _plan_level:
		_plan_level = level
		_plan = _pick_plan(level)
		_owned_ids.clear()
	if _plan == null:
		return
	var target: int = _plan.target_at(progress)
	var alive: int = get_alive_count()
	if is_reward_chunk:
		target += reward_chunk_extra
	_last_progress = progress
	_last_target = target
	var count: int = mini(target, max_alive) - alive
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
			_own(new_enemy)
			enemy_spawned.emit(new_enemy)
		if i < entries.size() - 1:
			await get_tree().create_timer(time_between_spawns, false).timeout


func _own(enemy: Enemy) -> void:
	_spawned.append(enemy)
	_owned_ids[enemy.get_instance_id()] = true


## An apple this spawner owns split: its children count toward the target too.
func _on_event_bus_enemy_summoned(enemy: Enemy) -> void:
	if enemy and enemy.has_meta(EnemySplit.SPLIT_FROM_META) \
			and _owned_ids.has(enemy.get_meta(EnemySplit.SPLIT_FROM_META)):
		_own(enemy)


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


# --- Debug readout ---

func _build_debug_label() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_debug_label = Label.new()
	_debug_label.anchor_left = 1.0
	_debug_label.anchor_right = 1.0
	_debug_label.offset_left = -170.0
	_debug_label.offset_top = 4.0
	_debug_label.offset_right = -4.0
	_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_debug_label.add_theme_font_size_override("font_size", 8)
	_debug_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_debug_label.add_theme_constant_override("outline_size", 3)
	_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_debug_label)


func _update_debug_label() -> void:
	var plan_name: String = _plan.display_name if _plan else "-"
	var world: GameWorld = get_parent() as GameWorld
	var in_world: int = 0
	if world:
		for enemy: Variant in world.current_enemies:
			if is_instance_valid(enemy) and not (enemy as Enemy).is_dead:
				in_world += 1
	_debug_label.text = "Rift %d  plan: %s\nprogress %.2f  target %d\nspawner alive %d  (queued %d)\nall enemies in rift %d" % [
		_plan_level, plan_name, _last_progress, _last_target, get_alive_count(), _queued, in_world]

