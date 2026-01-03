class_name TraversalChunk extends RiftChunk

@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var apple_tree: AppleTree = $AppleTree_1

func extra_ready_functions() -> void:
	if apple_tree:
		apple_tree.enemy_spawner_tree.summoned.connect(add_enemy)
		
func add_enemy(_enemy: Enemy) -> void:
	if _enemy:
		rift.call_deferred("add_child",_enemy)
	pass
