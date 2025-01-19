class_name AddMoneyAction extends ButtonAction

func button_pressed_action(_button: Button,game_node: Node) -> void:
		for child in game_node.get_children():
			if child is MainMenu:
				for child_2 in child.get_children():
					if child_2 is Player:
						child_2.stats.money += 10000
						child_2.money_changed.emit(child_2.stats.money)
	
