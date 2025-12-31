class_name TraversalChunk extends RiftChunk

@onready var enemy_spawner: EnemySpawner = $EnemySpawner

func extra_ready_functions() -> void:
	if enemy_spawner:
		enemy_spawner.active = true
		enemy_spawner.summoned.connect(add_enemy)

func add_enemy(_enemy: Enemy) -> void:
	if _enemy:
		rift.call_deferred("add_child",_enemy)
	pass
