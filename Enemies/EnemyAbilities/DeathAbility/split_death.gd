class_name EnemySplit extends EnemyAbility

@export var split_amount: int = 2
@export var offset_radius: float = 64.0

func activate_ability(_enemy: Enemy) -> void:
	if not _enemy or not _enemy.stats.can_split:
		return
	var scene: PackedScene = load(_enemy.scene_file_path)
	var spawn_position: Vector2 = _enemy.global_position
	for i: int in split_amount:
		var new_enemy: Enemy = scene.instantiate()
		new_enemy.set_data(_enemy.stats)
		new_enemy.stats = new_enemy.stats.duplicate()
		new_enemy.stats.can_split = false
		var random_offset: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(0.0, offset_radius)
		new_enemy.global_position = spawn_position + random_offset
		new_enemy.stats.size = 0.5
		EventBus.enemy_summoned.emit(new_enemy)
