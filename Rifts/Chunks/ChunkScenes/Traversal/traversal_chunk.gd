class_name TraversalChunk extends RiftChunk

@onready var spawn_markers: Node2D = $SpawnMarkers
@export var direction: CustomVariables.directions

var islands: Array[Island] = []

func extra_ready_functions() -> void:
	bounds.player_entered.connect(on_player_enter)
	spawn_chance = 1
	for child in get_children():
		if child is Island:
			islands.append(child)
	spawn_game_objects()
	
func get_spawn_markers() -> Array:
	return spawn_markers.get_children()
	
func on_player_enter() -> void:
	if is_main_path and not visited:
		rift_level.main_path_visited_count += 1
	if allowed_spawn and not visited:
		rift_level.summon_enemy(is_main_path, is_side_path_terminal)
	visited = true
	
func spawn_game_objects() -> void:
	var amount: int = randi_range(1, islands.size())
	islands.shuffle()
	for i in amount:
		islands[i].spawn_game_object()
