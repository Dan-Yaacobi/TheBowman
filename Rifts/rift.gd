class_name Rift extends GameWorld

@export var rift_values: Array[float]

@onready var rift_generator: RiftGenerator = $RiftGenerator
@onready var rift_enemy_spawner: RiftEnemySpawner = $RiftEnemySpawner
@onready var loot_manager: LootManager = $LootManager

var rift_levels: Array[RiftLevel]

func add_rift_level(_rift: RiftLevel) -> void:
	if _rift:
		rift_levels.append(_rift)
		
func extra_set_world_functions() -> void:
	loot_manager.set_up()
	rift_enemy_spawner.enemy_spawned.connect(add_enemy)
	rift_generator.rift_created.connect(add_rift_level)
	
	PlayerManager.player.stats.rift_level += 1
	EventBus.entered_rift.emit()
	var rift_level: RiftLevel = rift_generator.generate(PlayerManager.player.stats.rift_level)
	rift_levels.append(rift_level)	
	rift_level.reparent(self)
	rift_level.get_summon_enemy.connect(call_enemy_spawner)

func call_enemy_spawner(level: int, _main_progress: float, is_main_path: bool, is_side_path_terminal: bool) -> void:
	rift_enemy_spawner.spawn_enemy(level, _main_progress, is_main_path, is_side_path_terminal)

func extra_exit_world_functions() -> void:
	loot_manager.unset_up()
	rift_enemy_spawner.enemy_spawned.disconnect(add_enemy)
	rift_generator.rift_created.disconnect(add_rift_level)
	#rift_generator._reset_world()
	for level in rift_levels:
		level.queue_free()
	rift_levels.clear()
	kill_all_enemies()
	despawn_equipments()
	queue_free()

func spawn_position() -> Vector2:
	return rift_levels[0].starting_chunk.spawn_position()

	
func _on_portal_entered() -> void:
	for level in rift_levels:
		level.queue_free()
	rift_levels.clear()
	kill_all_enemies()
	set_world()
	
