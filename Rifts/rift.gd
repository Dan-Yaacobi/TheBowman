class_name Rift extends GameWorld

enum Type{DIRT, SNOW, HELL}

@export var rift_values: Array[float]
@export var active_ability_pool: Array[ActiveAbility]

@onready var rift_generator: RiftGenerator = $RiftGenerator
@onready var rift_enemy_spawner: RiftEnemySpawner = $RiftEnemySpawner
@onready var loot_manager: LootManager = $LootManager

var rift_levels: Array[RiftLevel]
var respawn_position: Vector2

func add_rift_level(_rift: RiftLevel) -> void:
	if _rift:
		rift_levels.append(_rift)
		
func extra_set_world_functions() -> void:
	loot_manager.set_up()
	rift_enemy_spawner.enemy_spawned.connect(add_enemy)
	rift_generator.rift_created.connect(add_rift_level)
	
	PlayerManager.player.stats.rift_level += 1
	var rift_level: RiftLevel = rift_generator.generate(PlayerManager.player.stats.rift_level)
	rift_levels.append(rift_level)	
	rift_level.reparent(self)
	rift_level.get_summon_enemy.connect(call_enemy_spawner)
	has_respawns = true
	EventBus.respawn_player.connect(respawn)
	EventBus.rift_respawn_position.connect(set_respawn_pos)
	
func _on_world_ready() -> void:
	if PlayerManager.player.stats.rift_level == 1 and active_ability_pool.size() >= 3:
		EventBus.show_active_ability_picker.emit(active_ability_pool)
	EventBus.entered_rift.emit()

func call_enemy_spawner(level: int, _main_progress: float, chunk_index: int, is_main_path: bool, is_side_path_terminal: bool) -> void:
	rift_enemy_spawner.spawn_enemy(level, _main_progress, chunk_index, is_main_path, is_side_path_terminal)

func extra_exit_world_functions() -> void:
	loot_manager.unset_up()
	rift_enemy_spawner.enemy_spawned.disconnect(add_enemy)
	rift_generator.rift_created.disconnect(add_rift_level)
	for level in rift_levels:
		level.queue_free()
	rift_levels.clear()
	kill_all_enemies()
	despawn_equipments()
	queue_free()
	
func spawn_position() -> Vector2:
	return rift_levels[0].starting_chunk.spawn_position()

func _on_portal_entered() -> void:
	rift_enemy_spawner.reset_elite_state()
	for level in rift_levels:
		level.queue_free()
	rift_levels.clear()
	kill_all_enemies()
	set_world()

func set_respawn_pos(_position: Vector2) -> void:
	respawn_position = _position
	
func respawn() -> void:
	PlayerManager.player.global_position = respawn_position
