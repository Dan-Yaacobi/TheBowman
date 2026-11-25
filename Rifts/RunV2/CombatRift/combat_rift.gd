class_name CombatRift extends RunNodeWorld
## Base for hand-made combat layouts: make a layout with New Inherited Scene from
## CombatRiftBase.tscn, add islands, SpawnMarkers (anywhere in the scene), the chest, the
## scroll pedestal and an exit portal (Portal.tscn with Is Rift Portal on, usually a child of
## the exit island so it rides it), then assign it to Exit Portal. Before the player arrives an encounter set is rolled and placed on the
## markers, where its enemies wait; the exit stays locked until they're all dead.

signal rift_cleared

## The layout's own exit (Portal.tscn, Is Rift Portal on). Locked until the fight is cleared.
@export var exit_portal: Portal
@export_range(0,100,1,"suffix:%") var kills_required: float

## Where the "enemies left" counter sits, relative to the exit portal's position.
@export var exit_counter_offset: Vector2 = Vector2(0, -48)
@onready var loot_manager: LootManager = $LootManager
@onready var encounter_director: EncounterDirector = $EncounterDirector

var is_cleared: bool = false
var _exit_counter: ExitLockCounter

## Layout test (debug hub portal): no run state, free falls, a chosen or empty encounter.
var _test_mode: bool = false
var _test_encounter: EncounterSet = null
var _test_empty: bool = false


## Called by GameManager before the layout enters the tree.
func setup_test(encounter: EncounterSet, empty: bool) -> void:
	_test_mode = true
	_test_encounter = encounter
	_test_empty = empty
	# Not a run: no tracker record or blessing use, and dying doesn't save or show the summary.
	counts_as_node = false
	counts_as_run = false


func extra_node_set_functions() -> void:
	loot_manager.set_up()
	if _test_mode:
		($FallingDeath as FallingDeath).costs_heart = false
		add_child(LayoutTestSpawnPanel.new())
	if exit_portal == null:
		push_error("%s: assign Exit Portal in the inspector" % name)
	else:
		exit_portal.set_locked(true)
		# A sibling of the portal, so it rides the same island.
		_exit_counter = ExitLockCounter.new()
		_exit_counter.position = exit_portal.position + exit_counter_offset
		exit_portal.get_parent().add_child.call_deferred(_exit_counter)
		encounter_director.alive_count_changed.connect(_on_encounter_director_alive_count_changed)
	# Deferred: the previous world is still connected to enemy_summoned until it exits later
	# this frame, and would claim the enemies. Still placed before the fade-in.
	_place_encounter.call_deferred()


func extra_node_exit_functions() -> void:
	loot_manager.unset_up()


func _place_encounter() -> void:
	if not is_inside_tree():
		return
	encounter_director.encounter_cleared.connect(_on_encounter_director_encounter_cleared, CONNECT_ONE_SHOT)
	var biome: int = CustomVariables.biome_index(PlayerManager.player.stats.rift_level)
	encounter_director.populate(_find_spawn_markers(self), biome, _is_late_in_act(), _test_encounter, _test_empty)
	if encounter_director.is_cleared():
		_on_encounter_director_encounter_cleared()


## Second half of the act rolls late encounter sets.
func _is_late_in_act() -> bool:
	if route == null:
		return false
	return route.nodes_done_in_act * 2 >= route.nodes_per_act


func _find_spawn_markers(root: Node) -> Array[SpawnMarker]:
	var found: Array[SpawnMarker] = []
	for child: Node in root.get_children():
		if child is SpawnMarker:
			found.append(child)
		found.append_array(_find_spawn_markers(child))
	return found


func _on_encounter_director_encounter_cleared() -> void:
	if is_cleared:
		return
	is_cleared = true
	if is_instance_valid(_exit_counter):
		_exit_counter.queue_free()
	if exit_portal:
		exit_portal.set_locked(false)
		CombatTextSpawner.spawn(exit_portal.global_position + Vector2(0, -30), "Cleared", Color.WHITE)
	rift_cleared.emit()


func _on_encounter_director_alive_count_changed(count: int) -> void:
	if is_instance_valid(_exit_counter):
		_exit_counter.set_count(count)
