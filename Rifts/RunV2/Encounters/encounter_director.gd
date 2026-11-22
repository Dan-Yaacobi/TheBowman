class_name EncounterDirector extends Node
## Runs one combat rift's fight. Before the player arrives it rolls an encounter set and puts
## one enemy on each spawn marker (ground enemies on GROUND markers, flyers on AIR).
## Flyers sleep on their spot until the player comes within their wake radius or damages them.
## Ground enemies (golems, rooted enemies) land on the island below and use their own dormant
## state, so they keep riding moving islands and keep their own wake / re-sleep rules.
## encounter_cleared fires once every placed enemy (and anything split from one) is dead.

signal encounter_cleared

@export var pool: EncounterPool
## A flyer wakes when the player gets this close. A marker's own wake_radius overrides it.
@export var wake_radius: float = 120.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var encounter: EncounterSet = null

var _alive: Array[Enemy] = []
## Ids of every enemy this director placed, kept after death so split children can be claimed.
var _owned_ids: Dictionary[int, bool] = {}
## Sleeping enemy -> its wake radius.
var _sleepers: Dictionary[Enemy, float] = {}
## Collision objects of sleeping enemies -> their disable mode before sleeping.
var _kept_active: Dictionary[Enemy, Dictionary] = {}
var _running: bool = false


func _ready() -> void:
	EventBus.enemy_summoned.connect(_on_event_bus_enemy_summoned)
	EventBus.enemy_damaged.connect(_on_event_bus_enemy_damaged)


## Rolls the encounter and places it. Call before the player arrives.
func populate(markers: Array[SpawnMarker], biome: int, late: bool) -> void:
	encounter = pool.roll(biome, late, rng) if pool else null
	var entries: Array[EnemyEntry] = []
	if encounter:
		entries = encounter.get_spawn_list()
	if entries.is_empty() or markers.is_empty():
		push_warning("EncounterDirector: no encounter or no spawn markers; the rift counts as cleared")
		return
	_running = true
	var free: Dictionary[SpawnMarker.Zone, Array] = {}
	for entry: EnemyEntry in entries:
		var marker: SpawnMarker = _take_marker(_zone_for(entry), markers, free)
		_place(entry, marker)


## True once the fight is over (or there never was one).
func is_cleared() -> bool:
	return not _running


func _process(_delta: float) -> void:
	if not _running:
		return
	_wake_near_player()
	if get_alive_count() == 0:
		_running = false
		encounter_cleared.emit()


func get_alive_count() -> int:
	var still: Array[Enemy] = []
	for enemy: Enemy in _alive:
		if is_instance_valid(enemy) and not enemy.is_dead:
			still.append(enemy)
	_alive = still
	return _alive.size()


# --- Placing ---

func _place(entry: EnemyEntry, marker: SpawnMarker) -> void:
	var enemy: Enemy = entry.get_factory().call()
	enemy.global_position = marker.global_position
	var radius: float = marker.wake_radius if marker.wake_radius > 0.0 else wake_radius
	_own(enemy)
	# Ground enemies have their own dormant state; only flyers are put to sleep here.
	if _zone_for(entry) == SpawnMarker.Zone.AIR:
		enemy.ready.connect(_on_flyer_ready.bind(enemy, radius), CONNECT_ONE_SHOT)
	EventBus.enemy_summoned.emit(enemy)


func _on_flyer_ready(enemy: Enemy, radius: float) -> void:
	_sleepers[enemy] = radius
	_sleep(enemy)


## One marker per enemy, picked without replacement within the zone. When a zone runs out it
## starts over (markers get shared); a zone the layout lacks borrows from every marker.
func _take_marker(zone: SpawnMarker.Zone, markers: Array[SpawnMarker],
		free: Dictionary[SpawnMarker.Zone, Array]) -> SpawnMarker:
	var bag: Array = free.get(zone, [])
	if bag.is_empty():
		for marker: SpawnMarker in markers:
			if marker.zone == zone:
				bag.append(marker)
		if bag.is_empty():
			bag = markers.duplicate()
		bag.shuffle()
		free[zone] = bag
	return bag.pop_back()


## Ground enemies use island spawn zones; everything else flies.
func _zone_for(entry: EnemyEntry) -> SpawnMarker.Zone:
	if entry.spawn_zone == SpawnHandler.Zone.ISLAND or entry.spawn_zone == SpawnHandler.Zone.ISLAND_CENTER:
		return SpawnMarker.Zone.GROUND
	return SpawnMarker.Zone.AIR


func _own(enemy: Enemy) -> void:
	_alive.append(enemy)
	_owned_ids[enemy.get_instance_id()] = true


# --- Sleeping ---

## Stops everything the enemy does (AI, timers, movement, animation) but keeps its collision
## active, so it can be shot while it waits.
func _sleep(enemy: Enemy) -> void:
	var modes: Dictionary = {}
	for node: Node in _collision_objects(enemy):
		var body: CollisionObject2D = node as CollisionObject2D
		modes[body] = body.disable_mode
		body.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	_kept_active[enemy] = modes
	enemy.process_mode = Node.PROCESS_MODE_DISABLED


func _wake(enemy: Enemy) -> void:
	_sleepers.erase(enemy)
	if not is_instance_valid(enemy):
		return
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	var modes: Dictionary = _kept_active.get(enemy, {})
	for body: Variant in modes:
		if is_instance_valid(body):
			(body as CollisionObject2D).disable_mode = modes[body]
	_kept_active.erase(enemy)


func _wake_near_player() -> void:
	if _sleepers.is_empty() or PlayerManager.player == null:
		return
	var player_pos: Vector2 = PlayerManager.player.global_position
	for enemy: Enemy in _sleepers.keys():
		if not is_instance_valid(enemy) or enemy.is_dead:
			_sleepers.erase(enemy)
			continue
		if enemy.global_position.distance_to(player_pos) <= _sleepers[enemy]:
			_wake(enemy)


func _collision_objects(root: Node) -> Array[Node]:
	var found: Array[Node] = []
	if root is CollisionObject2D:
		found.append(root)
	for child: Node in root.get_children():
		found.append_array(_collision_objects(child))
	return found


## A splitter this director owns split: its children have to die too.
func _on_event_bus_enemy_summoned(enemy: Enemy) -> void:
	if not _running or enemy == null or _alive.has(enemy):
		return
	if enemy.has_meta(EnemySplit.SPLIT_FROM_META) and _owned_ids.has(enemy.get_meta(EnemySplit.SPLIT_FROM_META)):
		_own(enemy)


## Getting hit wakes a sleeper.
func _on_event_bus_enemy_damaged(enemy: Enemy, _amount: int) -> void:
	if _sleepers.has(enemy):
		_wake(enemy)
