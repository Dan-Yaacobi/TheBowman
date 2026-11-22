class_name EncounterDirector extends Node
## Runs one combat rift's fight: rolls an encounter set and spawns its waves from the layout's
## SpawnMarkers. A wave starts once the previous one is down to next_wave_at_alive enemies;
## encounter_cleared fires when the last wave is dead. Finite: nothing spawns after that.

signal wave_started(index: int, count: int)
signal encounter_cleared

@export var pool: EncounterPool
## The next wave starts once this many (or fewer) enemies are still alive.
@export var next_wave_at_alive: int = 1
@export var time_between_spawns: float = 0.35
## Seconds after the player arrives before the first wave.
@export var first_wave_delay: float = 1.0
## Markers closer than this to the player are skipped while others are free.
@export var min_player_distance: float = 60.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var encounter: EncounterSet = null

var _markers: Array[SpawnMarker] = []
var _alive: Array[Enemy] = []
## Ids of every enemy this director spawned, kept after death so split children can be claimed.
var _owned_ids: Dictionary[int, bool] = {}
var _wave_index: int = -1
var _spawning: bool = false
var _running: bool = false


func _ready() -> void:
	set_process(false)
	EventBus.enemy_summoned.connect(_on_event_bus_enemy_summoned)


func start(markers: Array[SpawnMarker], biome: int, late: bool) -> void:
	_markers = markers
	encounter = pool.roll(biome, late, rng) if pool else null
	if encounter == null or encounter.waves.is_empty() or _markers.is_empty():
		push_warning("EncounterDirector: no encounter or no spawn markers; the rift counts as cleared")
		encounter_cleared.emit()
		return
	_running = true
	await get_tree().create_timer(first_wave_delay, false).timeout
	if not is_inside_tree():
		return
	set_process(true)


func get_alive_count() -> int:
	var still: Array[Enemy] = []
	for enemy: Enemy in _alive:
		if is_instance_valid(enemy) and not enemy.is_dead:
			still.append(enemy)
	_alive = still
	return _alive.size()


func _process(_delta: float) -> void:
	if not _running or _spawning:
		return
	var alive: int = get_alive_count()
	var last_wave: bool = _wave_index >= encounter.waves.size() - 1
	if last_wave:
		if alive == 0:
			_running = false
			set_process(false)
			encounter_cleared.emit()
	elif _wave_index < 0 or alive <= next_wave_at_alive:
		_spawn_wave(_wave_index + 1)


func _spawn_wave(index: int) -> void:
	_wave_index = index
	_spawning = true
	var entries: Array[EnemyEntry] = encounter.waves[index].get_spawn_list()
	wave_started.emit(index, entries.size())
	for i: int in entries.size():
		if not is_inside_tree():
			return
		_spawn(entries[i])
		if i < entries.size() - 1:
			await get_tree().create_timer(time_between_spawns, false).timeout
	_spawning = false


func _spawn(entry: EnemyEntry) -> void:
	var marker: SpawnMarker = _pick_marker(_zone_for(entry))
	if marker == null:
		push_warning("EncounterDirector: no spawn marker for %s" % entry.resource_path.get_file())
		return
	var enemy: Enemy = entry.get_factory().call()
	enemy.global_position = marker.global_position
	_own(enemy)
	EventBus.enemy_summoned.emit(enemy)


## Ground enemies use island spawn zones; everything else flies.
func _zone_for(entry: EnemyEntry) -> SpawnMarker.Zone:
	if entry.spawn_zone == SpawnHandler.Zone.ISLAND or entry.spawn_zone == SpawnHandler.Zone.ISLAND_CENTER:
		return SpawnMarker.Zone.GROUND
	return SpawnMarker.Zone.AIR


## A random marker of the zone, away from the player when possible. Falls back to any marker
## if the layout has none of that zone.
func _pick_marker(zone: SpawnMarker.Zone) -> SpawnMarker:
	var of_zone: Array[SpawnMarker] = []
	for marker: SpawnMarker in _markers:
		if marker.zone == zone:
			of_zone.append(marker)
	if of_zone.is_empty():
		of_zone = _markers.duplicate()
	var player_pos: Vector2 = PlayerManager.player.global_position if PlayerManager.player else Vector2.INF
	var far: Array[SpawnMarker] = []
	for marker: SpawnMarker in of_zone:
		if marker.global_position.distance_to(player_pos) >= min_player_distance:
			far.append(marker)
	var choices: Array[SpawnMarker] = far if not far.is_empty() else of_zone
	return choices[rng.randi_range(0, choices.size() - 1)]


func _own(enemy: Enemy) -> void:
	_alive.append(enemy)
	_owned_ids[enemy.get_instance_id()] = true


## A splitter this director owns split: its children have to die too.
func _on_event_bus_enemy_summoned(enemy: Enemy) -> void:
	if not _running or enemy == null or _alive.has(enemy):
		return
	if enemy.has_meta(EnemySplit.SPLIT_FROM_META) and _owned_ids.has(enemy.get_meta(EnemySplit.SPLIT_FROM_META)):
		_own(enemy)
