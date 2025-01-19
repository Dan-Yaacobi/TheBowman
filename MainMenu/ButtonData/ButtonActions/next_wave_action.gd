class_name NextWaveAction extends ButtonAction

func button_pressed_action(_button: Button,game_node: Node) -> void:
	if _button.button_pressed == true:
		var new_wave: int
		if game_node is Game:
			for child in game_node.get_children():
				if child is PlayGround:
					child.wave_data.current_wave += 1
					new_wave = child.wave_data.current_wave
			for child in game_node.get_children():
				if child is MainMenu:
					child.update_wave_label(new_wave)
