class_name ResetWaves extends ButtonAction

func button_pressed_action(_button: Button,game_node: Node) -> void:
	if game_node is Game:
		game_node.get_playground().change_wave(1)
