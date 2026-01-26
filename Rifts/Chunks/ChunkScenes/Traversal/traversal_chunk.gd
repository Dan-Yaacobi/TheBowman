class_name TraversalChunk extends 

const APPLE_TREE = preload("uid://tpty2gvjhn30")
@onready var spawn_markers: Node2D = $SpawnMarkers

@export var direction: CustomVariables.directions

func extra_ready_functions() -> void:
	if allowed_spawn:
		if randf() < spawn_chance:
			var new_tree: AppleTree = APPLE_TREE.instantiate()
			new_tree.global_position = spawn_markers.get_children().pick_random().global_position
			add_child(new_tree)


func add_enemy(_enemy: Enemy) -> void:
	if _enemy:
		rift.call_deferred("add_child",_enemy)
	pass
