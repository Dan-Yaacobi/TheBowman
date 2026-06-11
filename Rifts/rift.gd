class_name Rift extends GameWorld

@export var rift_values: Array[float]

@onready var rift_generator: RiftGenerator = $RiftGenerator
@onready var rift_enemy_spawner: RiftEnemySpawner = $RiftEnemySpawner
@onready var loot_manager: LootManager = $LootManager

var current_enemies: Array[Enemy]
var rift_levels: Array[RiftLevel]


func _ready() -> void:
	pass

func add_rift_level(_rift: RiftLevel) -> void:
	if _rift:
		rift_levels.append(_rift)

func set_world() -> void:
	loot_manager.set_up()
	EventBus.enemy_summoned.connect(add_enemy)
	EventBus.enemy_died.connect(remove_enemy)
	EventBus.summon_effect.connect(summon_effect)
	EventBus.equipment_dropped.connect(drop_equipment)
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

func exit_world() -> void:
	loot_manager.unset_up()
	EventBus.enemy_summoned.disconnect(add_enemy)
	EventBus.enemy_died.disconnect(remove_enemy)
	EventBus.summon_effect.disconnect(summon_effect)
	EventBus.equipment_dropped.disconnect(drop_equipment)
	rift_enemy_spawner.enemy_spawned.disconnect(add_enemy)
	rift_generator.rift_created.disconnect(add_rift_level)
	PlayerManager.player.hide_buffs()
	#rift_generator._reset_world()
	for level in rift_levels:
		level.queue_free()
	rift_levels.clear()
	kill_all_enemies()
	despawn_equipments()
	queue_free()
	pass

func spawn_position() -> Vector2:
	return rift_levels[0].starting_chunk.spawn_position()

func exit_scene(_player) -> void:
	PlayerManager.player.hide_buffs()

	if EventBus.summon_effect.is_connected(summon_effect):
		EventBus.summon_effect.disconnect(summon_effect)
	kill_all_enemies()
	
func _on_portal_entered() -> void:
	for level in rift_levels:
		level.queue_free()
	rift_levels.clear()
	kill_all_enemies()
	set_world()
	#game_manager.spawn_player(spawn_position())	
	
func add_enemy(_enemy: Enemy) -> void:
	if _enemy:
		current_enemies.append(_enemy)
		if _enemy.get_parent():
			_enemy.call_deferred("reparent", self)
		else:
			call_deferred("add_child",_enemy)

func remove_enemy(_enemy: Enemy) -> void:
	current_enemies.erase(_enemy)
	
func kill_all_enemies() -> void:
	for enemy in current_enemies:
		remove_enemy(enemy)
		enemy.queue_free()
		
func despawn_equipments() -> void:
	for child in get_children():
		if child is Equipment:
			child.clear_item(child)

func drop_equipment(equip_data: EquipmentData, _position: Vector2, _existing_equip: Equipment = null) -> void:
	var new_equip: Equipment
	if _existing_equip:
		new_equip = _existing_equip
	else:
		new_equip = equip_data.equipment_scene.instantiate()
		new_equip.data = equip_data

	new_equip.global_position = _position
	if not new_equip.get_parent():
		call_deferred("add_child",new_equip)
	else:
		new_equip.call_deferred("reparent", self)


func summon_effect(effect: Node2D) -> void:
	call_deferred("add_child", effect)
