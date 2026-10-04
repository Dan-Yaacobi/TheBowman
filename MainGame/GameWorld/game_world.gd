class_name GameWorld extends Node2D

@export var event_offset: Vector2 = Vector2(0.0, -50000.0)

var effects: Array[Node2D] = []
var current_enemies: Array[Enemy] = []
var has_respawns: bool = false
var respawn_position: Vector2
var current_event: Event = null
var suspended_enemies: Array[Enemy] = []
var _event_return_position: Vector2 = Vector2.ZERO

func set_world() -> void:
	EventBus.enemy_summoned.connect(add_enemy)
	EventBus.enemy_died.connect(remove_enemy)
	EventBus.summon_effect.connect(summon_effect)
	EventBus.equipment_dropped.connect(drop_equipment)
	EventBus.world_ready.connect(_on_world_ready, CONNECT_ONE_SHOT)
	EventBus.rift_respawn_position.connect(set_respawn_pos)
	EventBus.respawn_player.connect(respawn)

	extra_set_world_functions()

func exit_world() -> void:
	if is_instance_valid(current_event):
			current_event.on_event_exited()
	EventBus.enemy_summoned.disconnect(add_enemy)
	EventBus.enemy_died.disconnect(remove_enemy)
	EventBus.summon_effect.disconnect(summon_effect)
	EventBus.equipment_dropped.disconnect(drop_equipment)
	EventBus.respawn_player.disconnect(respawn)
	EventBus.rift_respawn_position.disconnect(set_respawn_pos)
	
	remove_effects()
	_clear_event()
	extra_exit_world_functions() 

func extra_set_world_functions() -> void:
	pass
	
func extra_exit_world_functions() -> void:
	pass
	
func _on_world_ready() -> void:
	pass

func on_world_ready() -> void:
	pass
	
func spawn_position() -> Vector2:
	return Vector2.ZERO

func summon_effect(effect: Node2D) -> void:
	effects.append(effect)
	if effect.get_parent():
		effect.reparent(self)
	else:
		call_deferred("add_child", effect)

		
func remove_effects() -> void:
	for effect in effects.duplicate():
		if is_instance_valid(effect):
			effect.queue_free()
	effects.clear()
			
func remove_effect(effect: Node2D) -> void:
	effects.erase(effect)

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
	for enemy: Enemy in current_enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_enemies.clear()

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
func enter_event(event_scene: PackedScene, return_position: Vector2) -> Vector2:
	_event_return_position = return_position
	_suspend_world()
	extra_enter_event_functions()
	current_event = event_scene.instantiate()
	current_event.position = event_offset
	add_child(current_event)
	return current_event.get_event_spawn()

func exit_event() -> Vector2:
	current_event.on_event_exited()
	kill_all_enemies()
	remove_effects()
	_clear_event()
	_resume_world()
	extra_exit_event_functions()
	return _event_return_position

func extra_enter_event_functions() -> void:
	pass

func extra_exit_event_functions() -> void:
	pass

func _suspend_world() -> void:
	remove_effects()
	for enemy in current_enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			enemy.hide()
			suspended_enemies.append(enemy)
	current_enemies.clear()

func _resume_world() -> void:
	for enemy in suspended_enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
			enemy.show()
			current_enemies.append(enemy)
	suspended_enemies.clear()

func _clear_event() -> void:
	if is_instance_valid(current_event):
		current_event.queue_free()
	current_event = null

func set_respawn_pos(_position: Vector2) -> void:
	respawn_position = _position
	
func respawn() -> void:
	PlayerManager.player.global_position = respawn_position
