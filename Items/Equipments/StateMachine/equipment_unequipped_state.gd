class_name EquipmentUnEquippedState extends EquipmentState

func init() -> void:
	pass

func Enter() -> void:
	_remove_stats_from_player()
	_reparent_to_world()
	_disable_player_interaction()
	equipment.show()
	equipment.is_landed = false
	state_machine.ChangeState(state_machine.states[0]) # EquipmentDroppedState

func Exit() -> void:
	pass

func Process(_delta: float) -> EquipmentState:
	return null

func Physics(_delta: float) -> EquipmentState:
	return null

func _remove_stats_from_player() -> void:
	# reverse whatever was applied in EquipmentEquippedState._apply_stats_to_player()
	# e.g. player.stats.damage.remove_modifier(equipment.data.damage_modifier)
	pass

func _reparent_to_world() -> void:
	# reparent equipment back to the world scene from the player node
	# e.g. equipment.reparent(get_tree().current_scene)
	# preserve global position so it drops from where the player is
	pass

func _disable_player_interaction() -> void:
	# disable the interaction area so the player cannot immediately
	# re-interact with the item they just unequipped
	# re-enable it once the player exits and re-enters the interaction area
	equipment.interaction_area.monitoring = false
func HandleInput(_event: InputEvent) -> EquipmentState:
	return null
