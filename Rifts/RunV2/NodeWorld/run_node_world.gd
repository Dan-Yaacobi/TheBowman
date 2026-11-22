class_name RunNodeWorld extends GameWorld
## Shared base for Run Structure v2 worlds (crossroads and nodes): player spawn, respawn,
## biome sky, and freeing itself on exit.

## Indexed by biome (dirt, snow, hell).
@export var sky_colors: Array[SkyColors] = []

@onready var player_spawn: PlayerSpawn = $PlayerSpawn


func extra_set_world_functions() -> void:
	has_respawns = true
	respawn_position = spawn_position()
	var biome: int = CustomVariables.biome_index(PlayerManager.player.stats.rift_level)
	if biome < sky_colors.size() and sky_colors[biome] != null:
		EventBus.change_sky_color.emit(sky_colors[biome])
	extra_node_set_functions()


func extra_exit_world_functions() -> void:
	extra_node_exit_functions()
	kill_all_enemies()
	despawn_equipments()
	queue_free()


func spawn_position() -> Vector2:
	return player_spawn.global_position


func extra_node_set_functions() -> void:
	pass


func extra_node_exit_functions() -> void:
	pass
