class_name EquipmentEquippedState extends EquipmentState
@onready var un_equipped: EquipmentUnEquippedState = $"../UnEquipped"

func init() -> void:
	pass
	
func Enter() -> void:
	equipment.equip_to_player()
	_update_equipment_ui()
	equipment.hide()
	
func Exit() -> void:
	return
	
func Process(_delta: float) -> EquipmentState:
	return null
	
func Physics(_delta: float) -> EquipmentState:
	return null
	
func _update_equipment_ui() -> void:
	pass
	
func HandleInput(_event: InputEvent) -> EquipmentState:
	return null
