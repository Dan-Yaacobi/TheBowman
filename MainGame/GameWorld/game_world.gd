class_name GameWorld extends Node2D

var effects: Array[Node2D] = []
var current_enemies: Array[Enemy] = []
func set_world() -> void:
	EventBus.enemy_summoned.connect(add_enemy)
	EventBus.enemy_died.connect(remove_enemy)
	EventBus.summon_effect.connect(summon_effect)
	EventBus.equipment_dropped.connect(drop_equipment)
	extra_set_world_functions()

func exit_world() -> void:
	EventBus.enemy_summoned.disconnect(add_enemy)
	EventBus.enemy_died.disconnect(remove_enemy)
	EventBus.summon_effect.disconnect(summon_effect)
	EventBus.equipment_dropped.disconnect(drop_equipment)
	remove_effects()
	extra_exit_world_functions() 

func extra_set_world_functions() -> void:
	pass
func extra_exit_world_functions() -> void:
	pass


func on_world_ready() -> void:
	pass
	
func spawn_position() -> Vector2:
	return Vector2.ZERO

func summon_effect(effect: Node2D) -> void:
	effects.append(effect)
	add_child(effect)

func remove_effects() -> void:
	for effect in effects:
		remove_effect(effect)
		if is_instance_valid(effect):
			effect.queue_free()

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
	for enemy in current_enemies:
		remove_enemy(enemy)
		if is_instance_valid(enemy):
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
