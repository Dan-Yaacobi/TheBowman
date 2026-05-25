class_name TraversalChunk extends RiftChunk

const APPLE_TREE = preload("uid://tpty2gvjhn30")
@onready var spawn_markers: Node2D = $SpawnMarkers

@export var direction: CustomVariables.directions

func extra_ready_functions() -> void:
	bounds.player_entered.connect(on_player_enter)
	spawn_chance = 1
	
func get_spawn_markers() -> Array:
	return spawn_markers.get_children()
	
func on_player_enter() -> void:
	if allowed_spawn:
		if randf() < spawn_chance:
			rift_level.summon_enemy()
