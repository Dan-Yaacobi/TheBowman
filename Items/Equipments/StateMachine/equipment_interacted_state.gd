class_name EquipmentInteractedState extends EquipmentState

func init() -> void:
	pass

func Enter() -> void:
	_pause_game_loop()
	_shift_camera_up()
	_open_comparison_window()

func Exit() -> void:
	_close_comparison_window()
	_restore_camera()
	_unpause_game_loop()

func Process(_delta: float) -> EquipmentState:
	return null

func Physics(_delta: float) -> EquipmentState:
	return null

func on_equip_pressed() -> void:
	# called by the UI equip button signal
	state_machine.ChangeState(state_machine.states[3]) # EquipmentEquippedState

func on_cancelled() -> void:
	# called if player walks away or presses cancel
	state_machine.ChangeState(state_machine.states[1]) # EquipmentOnGroundState

func _pause_game_loop() -> void:
	# pause the game tree or relevant entities
	# e.g. get_tree().paused = true, ensure equipment has process_mode = PROCESS_MODE_ALWAYS
	pass

func _unpause_game_loop() -> void:
	# unpause what was paused in _pause_game_loop
	pass

func _shift_camera_up() -> void:
	# shift the player's camera slightly upward to make room for the UI
	pass

func _restore_camera() -> void:
	# restore camera to its default offset
	pass

func _open_comparison_window() -> void:
	# open the equipment comparison UI window
	# pass equipment.data as the new item
	# pass the player's currently equipped item in the same slot for comparison
	# if no item is equipped in that slot, show only the new item stats
	pass

func _close_comparison_window() -> void:
	# close and hide the comparison UI window
	pass
