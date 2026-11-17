class_name ImpPack extends Enemy
## Invisible, unhittable spawner: releases pack_size imps at once so they rush together,
## then frees itself once they're all gone (which also frees its spawn cost).

var _imps: Array[Imp] = []
var _spawned: bool = false


func _physics_process(_delta: float) -> void:
	if not _spawned:
		_spawn_imps()
		return
	for imp: Imp in _imps:
		if is_instance_valid(imp):
			return
	queue_free()


func _spawn_imps() -> void:
	_spawned = true
	var data: ImpPackData = stats as ImpPackData
	for i: int in data.pack_size:
		var imp: Imp = data.imp_scene.instantiate()
		imp.set_data(data.imp_data)
		var offset: float = (i - (data.pack_size - 1) * 0.5) * data.spread
		imp.global_position = global_position + Vector2(offset, randf_range(-4.0, 4.0))
		_imps.append(imp)
		EventBus.enemy_summoned.emit(imp)


## Removed from outside (test room "Clear all", world cleanup): take the imps with it.
## Not _exit_tree: the world reparents enemies, which also leaves the tree.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for imp: Imp in _imps:
			if is_instance_valid(imp):
				imp.queue_free()
