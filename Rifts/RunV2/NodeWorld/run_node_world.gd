class_name RunNodeWorld extends GameWorld
## Shared base for Run Structure v2 worlds (crossroads and nodes): player spawn, respawn,
## biome sky, and freeing itself on exit.

## Indexed by biome (dirt, snow, hell).
@export var sky_colors: Array[SkyColors] = []
## Nodes count as a rift for the run tracker and meta progress; crossroads don't.
@export var counts_as_node: bool = true

@onready var player_spawn: PlayerSpawn = get_node_or_null("PlayerSpawn")

var route: RunRoute


## Called by GameManager before the world enters the tree.
func set_route(_route: RunRoute) -> void:
	route = _route


func extra_set_world_functions() -> void:
	has_respawns = true
	var biome: int = CustomVariables.biome_index(PlayerManager.player.stats.rift_level)
	if biome < sky_colors.size() and sky_colors[biome] != null:
		EventBus.change_sky_color.emit(sky_colors[biome])
	extra_node_set_functions()
	respawn_position = spawn_position()


func extra_exit_world_functions() -> void:
	extra_node_exit_functions()
	kill_all_enemies()
	despawn_equipments()
	queue_free()


func _on_world_ready() -> void:
	if counts_as_node:
		EventBus.entered_rift.emit()


func spawn_position() -> Vector2:
	return player_spawn.global_position if player_spawn else global_position


func extra_node_set_functions() -> void:
	pass


func extra_node_exit_functions() -> void:
	pass
