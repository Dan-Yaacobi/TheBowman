class_name TraversalChunk extends RiftChunk

func extra_ready_functions() -> void:
	pass
func add_enemy(_enemy: Enemy) -> void:
	if _enemy:
		rift.call_deferred("add_child",_enemy)
	pass
