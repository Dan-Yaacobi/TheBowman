class_name PlatformBuyMenu extends Node2D

@onready var price_label: Label = $PriceLabel
@onready var buy_button: Button = $BuyButton

func _ready() -> void:
	disable()
	price_label.text = "Price: " + str(get_parent().price)
	buy_button.pressed.connect(buy)
	
func enable() -> void:
	visible = true
	buy_button.disabled = false
	
func disable() -> void:
	visible = false
	buy_button.disabled = true

func set_price_color(can_buy: bool) -> void:
	if can_buy:
		buy_button.add_theme_color_override("font_color", Color.WHITE)
		buy_button.disabled = false
	else:
		buy_button.add_theme_color_override("font_disabled_color", Color.RED)
		buy_button.disabled = true

func buy() -> void:
	get_parent().buy()
	pass
