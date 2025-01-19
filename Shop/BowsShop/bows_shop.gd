class_name BowsShop extends Node2D

signal changed_scene

@onready var tiles: TileMapLayer = $Tiles
@onready var enter: Area2D = $LeftDoor/Enter
@onready var current_money: CurrentMoney = $CurrentMoney
@onready var fall: Area2D = $Fall

var shop_weapons: Array[ShopWeapon] = []
var total_bows: int
var player: Player
var current_weapon_to_purchase: int = 0
var menu_tile_limit: Rect2i
var tile_size: int = 16

####### Functions for operating the shop #######
func _ready() -> void:
	enter.body_entered.connect(shop)
	for child in get_children():
		if child is ShopWeapon:
			shop_weapons.append(child)
	total_bows = shop_weapons.size()
	
func check_bows_bought() -> void:
	for bow_sprite_number in total_bows:
		if bow_sprite_number == player.current_weapon.weapon_data.sprite_frame:
			shop_weapons[bow_sprite_number].buy_button.enable_button()
		elif bow_sprite_number > player.current_weapon.weapon_data.sprite_frame:
			shop_weapons[bow_sprite_number].buy_button.disable_button()
		else:
			tiles.set_cell(shop_weapons[bow_sprite_number].data.block_coordinate,-1)

func check_if_can_buy() -> bool:
	if shop_weapons[current_weapon_to_purchase] != null:
		if player.stats.money >= current_bow_price():
			return true
	return false

func current_bow_price() -> int:
	return shop_weapons[current_weapon_to_purchase].data.price

func set_button_colors() -> void:
	if current_weapon_to_purchase < shop_weapons.size():
		if shop_weapons[current_weapon_to_purchase] != null:
			shop_weapons[current_weapon_to_purchase].change_button_color(check_if_can_buy())

####### Functions for setting the scene #######
func shop(b) -> void:
	if b is Player:
		changed_scene.emit("Shop")

func set_player_camera(_player: Player) -> void:
	_player.set_camera(menu_tile_limit,tile_size)

func set_scene(_player: Player) -> void:
		menu_tile_limit = tiles.get_used_rect()
		set_player_camera(_player)
		player = _player
		for child in get_children():
			if child is ShopWeapon:
				child.player = player
				child.set_shop_weapon()
		visible = true
		_player.global_position = Vector2(70,150)
		tiles.collision_enabled = true
		for child in get_children():
			if child is MainButton:
				child.disabled = false
				child.player = player
				child.enable_area()
		enable_doors()
		check_bows_bought()
		set_button_colors()
		current_money.update_current_money(_player.stats.money)
		if not fall.body_entered.is_connected(shop):
			fall.body_entered.connect(shop)

func update_money(_val: int) -> void:
	current_money.update_current_money(_val)

func exit_scene(_player) -> void:
	for child in get_children():
		if child is MainButton:
			child.disabled = true
			child.disable_area()
	tiles.collision_enabled = false
	if fall.body_entered.is_connected(shop):
		fall.body_entered.disconnect(shop)
	visible = false
	disable_doors()

func disable_doors() -> void:
	for child in get_children():
		if child is Door:
			child.disable_door()

func enable_doors() -> void:
	for child in get_children():
		if child is Door:
			child.enable_door()
