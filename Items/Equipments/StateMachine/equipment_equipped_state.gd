class_name EquipmentEquippedState extends EquipmentState

func init() -> void:
	pass

func Enter() -> void:
	_reparent_to_player()
	_apply_stats_to_player()
	_update_equipment_ui()
	equipment.hide()

func Exit() -> void:
	pass

func Process(_delta: float) -> EquipmentState:
	return null

func Physics(_delta: float) -> EquipmentState:
	return null

func _reparent_to_player() -> void:
	equipment.equip_to_player()
	# reparent this equipment node to the player node
	# e.g. equipment.reparent(player_reference)
	pass

func _apply_stats_to_player() -> void:
	# read stats from equipment.data and apply them to the player's stat system
	# e.g. player.stats.damage.add_modifier(equipment.data.damage_modifier)
	pass

func _update_equipment_ui() -> void:
	# update the equipment slot UI to display this item in its correct slot
	pass
func HandleInput(_event: InputEvent) -> EquipmentState:
	return null
