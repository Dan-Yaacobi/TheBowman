class_name BuyTower extends Control

signal bought

@onready var buy_tower: Button = $BuyTower
@onready var price_label: Label = $PriceLabel

@export var initial_cost: int = 500

var current_price: int
var player: Player

func _ready() -> void:
	buy_tower.pressed.connect(buy)

func set_player(_player) -> void:
	if _player != null:
		player = _player
		set_price()

func set_price() -> void:
	current_price = initial_cost + initial_cost*player.stats.towers.size()
	price_label.text = "Cost: " + str(current_price)
	if player.stats.money < current_price:
		buy_tower.add_theme_color_override("font_color", Color.RED)
	else:
		buy_tower.add_theme_color_override("font_color", Color.WHITE)

func buy() -> void:
	buy_tower.disabled = true
	if player != null:
		if player.buy(current_price):
			set_price()
			player.stats.add_tower()
			bought.emit()
	buy_tower.disabled = false
		
