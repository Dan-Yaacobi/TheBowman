class_name EquipmentInteractedState extends EquipmentState
@onready var on_ground: EquipmentOnGroundState = $"../OnGround"
@onready var equipped: EquipmentEquippedState = $"../Equipped"

func init() -> void:
	equipment.interaction_area.connect("body_exited", _on_player_exited)
	
func Enter() -> void:
	EventBus.equip_item.connect(on_equip_pressed)
	EventBus.equipment_interaction_enter.emit(equipment)
	_pause_game_loop()
	_shift_camera_up()

func Exit() -> void:
	EventBus.equip_item.disconnect(on_equip_pressed)
	EventBus.equipment_interaction_exit.emit(equipment)
	_restore_camera()
	_unpause_game_loop()

func Process(_delta: float) -> EquipmentState:
	return null

func Physics(_delta: float) -> EquipmentState:
	return null

func on_equip_pressed(equip: Equipment) -> void:
	if equip == equipment:
		var old_item: Equipment = PlayerManager.player.get_equipped_node_in_slot(equipment.data.slot)
		if old_item:
			old_item.become_unequipped()
		state_machine.ChangeState(equipped)
		
func on_cancelled() -> void:
	# called if player walks away or presses cancel
	state_machine.ChangeState(state_machine.states[1]) # EquipmentOnGroundState

func _pause_game_loop() -> void:
	#get_tree().paused = true
	# pause the game tree or relevant entities
	# e.g. get_tree().paused = true, ensure equipment has process_mode = PROCESS_MODE_ALWAYS
	pass

func _unpause_game_loop() -> void:
	#get_tree().paused = false
	# unpause what was paused in _pause_game_loop
	pass

func _shift_camera_up() -> void:
	# shift the player's camera slightly upward to make room for the UI
	pass

func _restore_camera() -> void:
	# restore camera to its default offset
	pass


func HandleInput(_event: InputEvent) -> EquipmentState:
	return null

func _on_player_exited(body: Node2D) -> void:
	if body is Player and state_machine.curr_state is EquipmentInteractedState:
		state_machine.ChangeState(on_ground)

func highlight() -> void:
	#highlights the interacted item
	pass
