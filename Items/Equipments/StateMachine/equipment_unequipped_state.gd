class_name EquipmentUnEquippedState extends EquipmentState
@onready var dropped: EquipmentDroppedState = $"../Dropped"

func init() -> void:
	pass
	
func Enter() -> void:
	_reparent_to_world()
	_disable_player_interaction()
	equipment.show()
	equipment.is_landed = false
	state_machine.ChangeState(dropped)
	
func Exit() -> void:
	equipment.sprite.scale = Vector2(1,1)
	pass
	
func Process(_delta: float) -> EquipmentState:
	return null
	
func Physics(_delta: float) -> EquipmentState:
	return null
	
func _remove_stats_from_player() -> void:
	equipment.unequip_from_player()
	
func _reparent_to_world() -> void:
	EventBus.equipment_dropped.emit(equipment.data,PlayerManager.player.global_position, equipment)

func _disable_player_interaction() -> void:
	equipment.interaction_area.monitoring = false
	
	equipment.interaction_area.body_exited.connect(_on_player_exited, CONNECT_ONE_SHOT)
	
func _on_player_exited(_body: Node2D) -> void:
	equipment.interaction_area.monitoring = true
	
func HandleInput(_event: InputEvent) -> EquipmentState:
	return null
