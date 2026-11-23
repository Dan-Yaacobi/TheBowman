class_name EncounterDirector extends Node
## Runs one combat rift's fight. Before the player arrives it rolls an encounter set and places
## it on the layout's spawn markers, one enemy per marker (ground enemies on GROUND markers,
## flyers on AIR). Always-fill markers are filled first, from the set or with an extra enemy of
## the set's types; the rest of the set goes on random other markers. So the fight is the set's
## size, or the number of always-fill markers if that's more.
## A marker activates when its flyer's wake radius reaches the player or its enemy is hit, and
## activates every marker within its link radius in turn (a chain). Activating wakes the
## sleeping flyers on those markers.
## Flyers sleep on their spot until the player comes within their wake radius or damages them.
## Ground enemies (golems, rooted enemies) land on the island below and use their own dormant
## state, so they keep riding moving islands and keep their own wake / re-sleep rules.
## encounter_cleared fires once every placed enemy (and anything split from one) is dead.

signal encounter_cleared

@export var pool: EncounterPool
## Fallback for markers whose wake_radius is 0.
@export var wake_radius: float = 120.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var encounter: EncounterSet = null

var _alive: Array[Enemy] = []
## Ids of every enemy this director placed, kept after death so split children can be claimed.
var _owned_ids: Dictionary[int, bool] = {}
## Sleeping enemy -> its wake radius.
var _sleepers: Dictionary[Enemy, float] = {}
## Placed enemy -> the marker it was placed on.
var _marker_of: Dictionary[Enemy, SpawnMarker] = {}
## Every marker in the layout, for link chains.
var _markers: Array[SpawnMarker] = []
var _activated: Dictionary[SpawnMarker, bool] = {}
## Collision objects of sleeping enemies -> their disable mode before sleeping.
var _kept_active: Dictionary[Enemy, Dictionary] = {}
var _running: bool = false


func _ready() -> void:
	EventBus.enemy_summoned.connect(_on_event_bus_enemy_summoned)
	EventBus.enemy_damaged.connect(_on_event_bus_enemy_damaged)


## Rolls the encounter and places it. Call before the player arrives.
## forced skips the roll (layout test); empty places nothing.
func populate(markers: Array[SpawnMarker], biome: int, late: bool,
		forced: EncounterSet = null, empty: bool = false) -> void:
	if empty:
		return
	encounter = forced if forced else (pool.roll(biome, late, rng) if pool else null)
	var entries: Array[EnemyEntry] = []
	if encounter:
		entries = encounter.get_spawn_list()
	if entries.is_empty() or markers.is_empty():
		push_warning("EncounterDirector: no encounter or no spawn markers; the rift counts as cleared")
		return
	_running = true
	_markers = markers
	entries.shuffle()
	var optional: Array[SpawnMarker] = []
	for marker: SpawnMarker in markers:
		if not marker.always_fill:
			optional.append(marker)
	for marker: SpawnMarker in markers:
		if marker.always_fill:
			var entry: EnemyEntry = _take_entry_for_zone(entries, marker.zone)
			if entry == null:
				entry = _extra_entry_for_zone(marker.zone)
			if entry:
				_place(entry, marker)
	var free: Dictionary[SpawnMarker.Zone, Array] = {}
	for entry: EnemyEntry in entries:
		_place(entry, _take_marker(_zone_for(entry), optional, markers, free))


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
	_marker_of[enemy] = marker
	# Ground enemies have their own dormant state; only flyers are put to sleep here.
	if _zone_for(entry) == SpawnMarker.Zone.AIR:
		enemy.ready.connect(_on_flyer_ready.bind(enemy, radius), CONNECT_ONE_SHOT)
	EventBus.enemy_summoned.emit(enemy)


func _on_flyer_ready(enemy: Enemy, radius: float) -> void:
	_sleepers[enemy] = radius
	_sleep(enemy)


## Removes and returns the first entry of the zone from the list; null if there's none.
func _take_entry_for_zone(entries: Array[EnemyEntry], zone: SpawnMarker.Zone) -> EnemyEntry:
	for i: int in entries.size():
		if _zone_for(entries[i]) == zone:
			return entries.pop_at(i)
	return null


## An extra enemy for an always-fill marker once the set has none of its zone left: one of the
## set's types of that zone (weighted by count), or of any zone if the set has none.
func _extra_entry_for_zone(zone: SpawnMarker.Zone) -> EnemyEntry:
	var options: Array[EnemyEntry] = []
	var weights: PackedFloat32Array = PackedFloat32Array()
	for pass_index: int in 2:
		for entry: EnemyEntry in encounter.enemies:
			if entry == null or encounter.enemies[entry] <= 0:
				continue
			if pass_index == 0 and _zone_for(entry) != zone:
				continue
			options.append(entry)
			weights.append(float(encounter.enemies[entry]))
		if not options.is_empty():
			break
	if options.is_empty():
		return null
	return options[rng.rand_weighted(weights)]


## A marker for one of the set's remaining enemies: a free non-always-fill marker of its zone,
## picked without replacement. When those run out they get reused; with none of the zone it
## uses always-fill markers of the zone, and a zone the layout lacks borrows from every marker.
func _take_marker(zone: SpawnMarker.Zone, optional: Array[SpawnMarker], all: Array[SpawnMarker],
		free: Dictionary[SpawnMarker.Zone, Array]) -> SpawnMarker:
	var bag: Array = free.get(zone, [])
	if bag.is_empty():
		for marker: SpawnMarker in optional:
			if marker.zone == zone:
				bag.append(marker)
		if bag.is_empty():
			for marker: SpawnMarker in all:
				if marker.zone == zone:
					bag.append(marker)
		if bag.is_empty():
			bag = all.duplicate()
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
		if _sleepers.has(enemy) and enemy.global_position.distance_to(player_pos) <= _sleepers[enemy]:
			_activate_enemy(enemy)


## Wakes the enemy and activates its marker (and the marker's link chain).
func _activate_enemy(enemy: Enemy) -> void:
	if _sleepers.has(enemy):
		_wake(enemy)
	var marker: SpawnMarker = _marker_of.get(enemy)
	if marker:
		_activate_marker(marker)


## Wakes the flyers sleeping on this marker, then every marker within its link radius in turn.
func _activate_marker(start: SpawnMarker) -> void:
	var queue: Array[SpawnMarker] = [start]
	while not queue.is_empty():
		var marker: SpawnMarker = queue.pop_back()
		if _activated.has(marker) or not is_instance_valid(marker):
			continue
		_activated[marker] = true
		for enemy: Enemy in _sleepers.keys():
			if _marker_of.get(enemy) == marker:
				_wake(enemy)
		if marker.link_radius <= 0.0:
			continue
		for other: SpawnMarker in _markers:
			if other != marker and not _activated.has(other) and is_instance_valid(other) \
					and other.global_position.distance_to(marker.global_position) <= marker.link_radius:
				queue.append(other)


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


## Getting hit activates the enemy's marker: it wakes (if it's a sleeping flyer) and so do
## the linked markers' flyers. Ground enemies handle their own waking.
func _on_event_bus_enemy_damaged(enemy: Enemy, _amount: int) -> void:
	if _marker_of.has(enemy):
		_activate_enemy(enemy)
