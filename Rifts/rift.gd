class_name Rift extends GameWorld

@export var rift_values: Array[float]

@onready var rift_generator: RiftGenerator = $RiftGenerator
@onready var rift_enemy_spawner: RiftEnemySpawner = $RiftEnemySpawner
@onready var loot_manager: LootManager = $LootManager

var current_enemies: Array[Enemy]
var rift_levels: Array[RiftLevel]

func _ready() -> void:
	EventBus.enemy_summoned.connect(add_enemy)
	EventBus.enemy_died.connect(remove_enemy)
	EventBus.summon_effect.connect(summon_effect)
	EventBus.equipment_dropped.connect(drop_equipment)
	rift_enemy_spawner.enemy_spawned.connect(add_enemy)
	
	rift_generator.rift_created.connect(add_rift_level)

func add_rift_level(_rift: RiftLevel) -> void:
	if _rift:
		rift_levels.append(_rift)

func set_world() -> void:
	PlayerManager.player.stats.rift_level += 1
	EventBus.entered_rift.emit()
	var rift_level: RiftLevel = rift_generator.generate(PlayerManager.player.stats.rift_level)
	rift_levels.append(rift_level)	
	rift_level.reparent(self)
	rift_level.get_summon_enemy.connect(call_enemy_spawner)

func call_enemy_spawner(level: int) -> void:
	rift_enemy_spawner.spawn_enemy(level)

func exit_world() -> void:
	PlayerManager.player.hide_buffs()
	#rift_generator._reset_world()
	for level in rift_levels:
		level.queue_free()
	rift_levels.clear()
	kill_all_enemies()
	queue_free()
	pass

func spawn_position() -> Vector2:
	return rift_levels[0].starting_chunk.spawn_position()

func set_scene(_player) -> void:
	#for i in range(20):
		#rift_generator.generate()
	_player.stats.rift_level += 1
	#print("called again")
	#var start_chunk: RiftLevel = rift_generator.generate(PlayerManager.player.stats.rift_level)
	#PlayerManager.player.global_position = start_chunk.spawn_position()
	PlayerManager.player.show_buffs()
	EventBus.entered_rift.emit()
	EventBus.summon_effect.connect(summon_effect)
	
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

func drop_equipment(equip_data: EquipmentData, _position: Vector2) -> void:
	var new_equip: Equipment = equip_data.equipment_scene.instantiate()
	new_equip.data = equip_data
	new_equip.global_position = _position
	call_deferred("add_child",new_equip)

func summon_effect(effect: Node2D) -> void:
	call_deferred("add_child", effect)
