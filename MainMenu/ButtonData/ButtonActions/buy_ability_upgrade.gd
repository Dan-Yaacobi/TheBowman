class_name BuyAbilityUpgrade extends ButtonAction

func button_pressed_action(_button: Button,game_node: Node) -> void:
	var node = _button.get_parent()
	if node is AbilitiesShopButton:
		node.buy_upgrade()
	pass
