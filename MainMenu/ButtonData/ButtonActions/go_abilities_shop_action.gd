class_name GoAbilityShopAction extends ButtonAction

func button_pressed_action(_button: Button,game_node: Node) -> void:
	if game_node is Game:
		game_node.change_scene("AbilitiesShop")
	pass
