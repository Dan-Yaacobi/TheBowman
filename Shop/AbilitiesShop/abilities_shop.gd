class_name AbilitiesShop extends Node2D

signal changed_scene

@onready var tiles: TileMapLayer = $Tiles
@onready var door_enter: Area2D = $LeftDoor/Enter

var menu_tile_limit: Rect2i
var tile_size: int = 16

func _ready() -> void:
	for child in get_children():
		if child is AbilitiesShopButton:
			child.bought.connect(set_buttons_colors)
	door_enter.body_entered.connect(menu)
	
func set_scene(_player: Player) -> void:
	if _player != null:
		_player.global_position = Vector2(85,160)
		menu_tile_limit = tiles.get_used_rect()
		_player.stats.in_menu = true
		set_player_camera(_player)
		visible = true
		tiles.collision_enabled = true
		enable_doors()
		for child in get_children():
			if child is AbilitiesShopButton:
				child.set_up(_player)
				
func exit_scene(_player) -> void:
	disable_doors()
	visible = false
	tiles.collision_enabled = false

func set_player_camera(_player: Player) -> void:
	_player.set_camera(menu_tile_limit,tile_size)

func disable_doors() -> void:
	for child in get_children():
		if child is Door:
			child.disable_door()
			
func enable_doors() -> void:
	for child in get_children():
		if child is Door:
			child.enable_door()

func set_buttons_colors() -> void:
	for child in get_children():
		if child is AbilitiesShopButton:
			child.set_buttons()

func menu(b) -> void:
	if b is Player:
		changed_scene.emit("Shop")
