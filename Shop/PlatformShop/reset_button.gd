class_name PlatformResetButton extends Button

@onready var tiles: TilesControl = $"../Tiles"
@onready var platform_shop: PlatformShop = $".."

var refund_value: int = 1
func _ready() -> void:
	pressed.connect(reset)
		
func reset() -> void:
	var refund_money: int = tiles.reset_tiles()
	
	refund_money *= refund_value
	platform_shop.refund(refund_money)
	platform_shop.reset_platforms()
