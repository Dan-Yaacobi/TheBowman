class_name BuyPlatformAction extends ButtonAction

func button_pressed_action(_button: Button,game_node: Node) -> void:
	if game_node is PlatformShop:
		game_node.buy_platforms(_button.get_parent().side)
	pass
	
