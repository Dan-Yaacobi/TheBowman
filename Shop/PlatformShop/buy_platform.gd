class_name BuyPlatform extends Node2D

@export var button_action: ButtonAction
@export var side: String
@export var upgrade_function: UpgradeFunction
@export var price: int
@onready var platform: Label = $Platform

@onready var price_label: Label = $Price
@onready var button: MainButton = $ButtonShootClick

func set_buttons() -> void:
	button.button_data.button_action = button_action
	update_price_label()
	platform.text = side + " Platform"
	
func check_if_can_buy(amount: int) -> int:
	if amount >= price:
		return price
	return 0

func update_price_label() -> void:
	price_label.text = "Price: " + str(price)
