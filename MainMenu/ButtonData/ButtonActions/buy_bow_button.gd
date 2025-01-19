class_name BuyBowButton extends ButtonAction

func button_pressed_action(_button: Button,game_node: Node) -> void:
	if game_node is BowsShop:
		for child in game_node.get_children():
			if child is Player:
				if _button.get_parent().data.bought:
					child.change_to_new_bow(_button.get_parent().data.weapon_scene)
					
				elif game_node.check_if_can_buy():
					_button.get_parent().data.bought = true
					child.change_to_new_bow(_button.get_parent().data.weapon_scene)
					game_node.check_bows_bought()
					child.collect_money(-game_node.current_bow_price())
					game_node.update_money(child.stats.money)
					game_node.current_weapon_to_purchase += 1
					game_node.set_button_colors()
					_button.clicked.emit()
