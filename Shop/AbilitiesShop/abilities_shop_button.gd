class_name AbilitiesShopButton extends Node2D

signal bought

@export var data: AbilitiesShopButtonData
@onready var main_button: MainButton = $ButtonShootClick
@onready var price_label: Label = $PriceLabel
@onready var current_stat_label: Label = $CurrentStat
@onready var buying_stat: Label = $BuyingStat
@export var upgrade_function: UpgradeFunction
@export var current_stat: String

var stats: Dictionary
var stats_update: Dictionary = {"HP": 1, "JUMP": 1, "Knockback Resistance": 1}
var player: Player
var player_stat_to_view: String = ""

func set_up(_player: Player) -> void:
	if _player != null:
		if data != null:
			buying_stat.text = "Upgrade " + data.ability
			main_button.button_data.button_action = data.buy_action
			player = _player
			stats = {"HP": player.stats.max_hp, "JUMP": player.stats.max_jumps,
			"Knockback Resistance":player.stats.knockback_resistance}
			set_price()
			buying_stat.add_theme_color_override("font_color",data.label_color)
			buying_stat.add_theme_color_override("font_shadow_color",data.label_color.darkened(0.2))
			buying_stat.add_theme_color_override("font_outline_color",data.label_color.darkened(0.4))
func set_price() -> void:
	if player != null:
		set_current_stat()
		data.price = upgrade_function.upgrade(player)
		price_label.text = "Price: " + str(data.price)
		current_stat_label.text = "Current " + ": " + player_stat_to_view
		
		set_buttons()

func set_buttons() -> void:
	if player.stats.money < data.price:
		main_button.disable_button()
		main_button.modulate = Color.RED
	else:
		main_button.enable_button()
		main_button.modulate = Color.WHITE

func set_current_stat() -> void:
	player_stat_to_view = str(stats[current_stat])

func buy_upgrade() -> void:
	if player != null:
		if player.stats.money >= data.price:
			player.stats.money -= data.price
			decide_stat_to_upgrade()
			set_price()
			bought.emit()

func decide_stat_to_upgrade() -> void:
	if current_stat == "HP":
		player.stats.max_hp += stats_update[current_stat]
		stats[current_stat] = player.stats.max_hp
		player.stats.hp = player.stats.max_hp
		player.health_bar.init_health(player.stats.max_hp)
		
	elif current_stat == "JUMP":
		player.stats.max_jumps += stats_update[current_stat]
		stats[current_stat] = player.stats.max_jumps
		player.jump_action.set_jumps()
		
	elif current_stat == "Knockback Resistance":
		player.stats.knockback_resistance += stats_update[current_stat]
		stats[current_stat] = player.stats.knockback_resistance
	pass
