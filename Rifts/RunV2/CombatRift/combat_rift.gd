class_name CombatRift extends RunNodeWorld
## Base for hand-made combat layouts: make a layout with New Inherited Scene from
## CombatRiftBase.tscn, add islands, SpawnMarkers (anywhere in the scene), the chest and the
## scroll pedestal. On arrival an encounter set is rolled and spawned in waves from the
## markers; the exit stays locked until it's cleared.

signal rift_cleared

@onready var exit_portal: Portal = $ExitPortal
@onready var loot_manager: LootManager = $LootManager
@onready var encounter_director: EncounterDirector = $EncounterDirector

var is_cleared: bool = false


func extra_node_set_functions() -> void:
	loot_manager.set_up()
	exit_portal.disable()


func extra_node_exit_functions() -> void:
	loot_manager.unset_up()


func on_world_ready() -> void:
	encounter_director.encounter_cleared.connect(_on_encounter_director_encounter_cleared, CONNECT_ONE_SHOT)
	var biome: int = CustomVariables.biome_index(PlayerManager.player.stats.rift_level)
	encounter_director.start(_find_spawn_markers(self), biome, _is_late_in_act())


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
	is_cleared = true
	exit_portal.enable()
	CombatTextSpawner.spawn(exit_portal.global_position + Vector2(0, -30), "Cleared", Color.WHITE)
	rift_cleared.emit()
