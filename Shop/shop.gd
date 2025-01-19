class_name Shop extends Node2D

@onready var enter_menu: Area2D = $Door/Enter
@onready var tiles: TileMapLayer = $Tiles
@onready var current_money: CurrentMoney = $CurrentMoney

signal changed_scene

var menu_tile_limit: Rect2i
var tile_size: int = 16
var player: Player

func _ready() -> void:
	enter_menu.body_entered.connect(menu)

func abilities_shop(b) -> void:
	if b is Player:
		changed_scene.emit("AbilitiesShop")
		
func menu(b) -> void:
	if b is Player:
		changed_scene.emit("Menu")
		
func set_player_camera(_player: Player) -> void:
	_player.set_camera(menu_tile_limit,tile_size)

func set_scene(_player: Player) -> void:
	if _player != null:
		player = _player
		visible = true
		menu_tile_limit = tiles.get_used_rect()
		set_player_camera(_player)
		_player.global_position = Vector2(300,104)
		tiles.collision_enabled = true
		#enter_menu.monitoring = true
		for child in get_children():
			if child is MainButton:
				child.disabled = false
				child.player = player
				child.enable_area()
		enable_doors()
		current_money.update_current_money(_player.stats.money)
		
func exit_scene(_player) -> void:
	for child in get_children():
		if child is MainButton:
			child.disabled = true
			child.disable_area()
	tiles.collision_enabled = false
	visible = false
	#enter_menu.monitoring = false
	disable_doors()
	pass

func disable_doors() -> void:
	for child in get_children():
		if child is Door:
			child.disable_door()
			
func enable_doors() -> void:
	for child in get_children():
		if child is Door:
			child.enable_door()
			
