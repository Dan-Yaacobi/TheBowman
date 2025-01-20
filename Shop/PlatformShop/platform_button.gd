class_name PlatformButton extends TextureButton

@onready var platform_buy_menu: PlatformBuyMenu = $PlatformBuyMenu
@export var price: int

var platform_shop: PlatformShop
var color_index: int = 0
var player: Player
var bought: bool = false

func _ready() -> void:
	pressed.connect(clicked)
	pass
	
func set_button(shop: PlatformShop,_player: Player) -> void:
	platform_shop = shop
	player = _player
	platform_buy_menu.disable()
	button_pressed = false
	
func clicked() -> void:
	if not bought:
		if platform_shop != null:
			if button_pressed:
				platform_buy_menu.enable()
				platform_buy_menu.set_price_color(check_if_can_buy())
			else:
				platform_buy_menu.disable()
	else:
		platform_buy_menu.disable()
		
func buy_platform() -> void:
	platform_shop.add_platform_at(global_position / 16,color_index)
	platform_buy_menu.disable()
	
func check_if_can_buy() -> bool:
	if player.stats.money >= price:
		return true
	return false

func buy() -> void:
	if check_if_can_buy():
		player.collect_money(-price)
		buy_platform()
		player.money_changed.emit(player.stats.money)
		bought = true
	pass

func reset() -> void:
	bought = false
	button_pressed = false
