class_name EnemySplit extends EnemyAbility

@export var split_amount: int = 2
@export var offset_radius: float = 15.0
@export var emerge_time: float = 0.9

func activate_ability(_enemy: Enemy) -> void:
	if not _enemy or not _enemy.stats.can_split:
		return
	var scene: PackedScene = load(_enemy.scene_file_path)
	var spawn_position: Vector2 = _enemy.global_position
	var base_angle: float = randf() * TAU
	var angle_step: float = TAU / split_amount
	for i: int in split_amount:
		var new_enemy: Enemy = scene.instantiate()
		new_enemy.set_data(_enemy.stats)
		new_enemy.stats = new_enemy.stats.duplicate()
		new_enemy.stats.can_split = false
		var jitter: float = randf_range(-angle_step * 0.25, angle_step * 0.25)
		var angle: float = base_angle + angle_step * i + jitter
		var random_offset: Vector2 = Vector2.from_angle(angle) * randf_range(offset_radius * 0.5, offset_radius)
		var target_position: Vector2 = spawn_position + random_offset
		var target_scale: Vector2 = new_enemy.scale * 0.5
		new_enemy.stats.max_hp *= 0.75
		new_enemy.global_position = spawn_position
		new_enemy.process_mode = Node.PROCESS_MODE_DISABLED
		new_enemy.ready.connect(_emerge.bind(new_enemy, target_position, target_scale), CONNECT_ONE_SHOT)
		EventBus.enemy_summoned.emit(new_enemy)


func _emerge(enemy: Enemy, target_position: Vector2, target_scale: Vector2) -> void:
	enemy.modulate.a = 0.0
	var tween: Tween = enemy.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(enemy, "modulate:a", 0.5, emerge_time * 0.4)
	tween.tween_property(enemy, "scale", target_scale, emerge_time * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "global_position", target_position, emerge_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(func() -> void:
		enemy.modulate.a = 1.0
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
	)
	
