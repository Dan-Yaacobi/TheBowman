class_name CombatRift extends RunNodeWorld
## Base for hand-made combat layouts: make a layout with New Inherited Scene from
## CombatRiftBase.tscn, add islands, SpawnMarkers (anywhere in the scene), the chest, the
## scroll pedestal and an exit portal (Portal.tscn with Is Rift Portal on, usually a child of
## the exit island so it rides it), then assign it to Exit Portal. Before the player arrives an encounter set is rolled and placed on the
## markers, where its enemies wait; the exit stays locked until they're all dead.

signal rift_cleared

## The layout's own exit (Portal.tscn, Is Rift Portal on). Locked until the fight is cleared.
@export var exit_portal: Portal
@onready var loot_manager: LootManager = $LootManager
@onready var encounter_director: EncounterDirector = $EncounterDirector

var is_cleared: bool = false


func extra_node_set_functions() -> void:
	loot_manager.set_up()
	if exit_portal == null:
		push_error("%s: assign Exit Portal in the inspector" % name)
	else:
		exit_portal.disable()
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
	encounter_director.populate(_find_spawn_markers(self), biome, _is_late_in_act())
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
	if exit_portal:
		exit_portal.enable()
		CombatTextSpawner.spawn(exit_portal.global_position + Vector2(0, -30), "Cleared", Color.WHITE)
	rift_cleared.emit()
