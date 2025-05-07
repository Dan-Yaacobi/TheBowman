class_name MainMenu extends Node2D

@onready var enter_fight: Area2D = $RightDoor/Enter
@onready var enter_shop: Area2D = $LeftDoor/Enter
@onready var wave_label: Label = $CurrentWaves
@onready var current_money: CurrentMoney = $CurrentMoney
@onready var tiles: TileMapLayer = $Tiles
@onready var hard_mode_button: Button = $HardMode
@onready var normal_mode_button: Button = $NormalMode

@onready var test_button: Button = $Button

var menu_tile_limit: Rect2i
var tile_size: int = 16
var playground: PlayGround

var hard_mode: bool = false

signal changed_scene

func _ready() -> void:
	hard_mode_button.pressed.connect(activate_hard_mode)
	normal_mode_button.pressed.connect(activate_normal_mode)
	enter_fight.body_entered.connect(start_fight)
	enter_shop.body_entered.connect(shop)
	var game = get_parent()
	if game is Game:
		game.get_playground().wave_reset.connect(update_wave_label)
	test_button.pressed.connect(test)

func test() -> void:
	changed_scene.emit("TowerUpgrade")
	pass
func activate_hard_mode() -> void:
	hard_mode = true
	playground.hard_mode = hard_mode
	
func activate_normal_mode() -> void:
	hard_mode = false
	playground.hard_mode = hard_mode
	
func start_fight(b) -> void:
	if b is Player:
		changed_scene.emit("PlayGround")

func shop(b) -> void:
	if b is Player:
		changed_scene.emit("Shop")

func set_player_camera(_player: Player) -> void:
	_player.set_camera(menu_tile_limit,tile_size)

func set_scene(_player: Player) -> void:
	if _player != null:
		_player.global_position = Vector2(185,104)
		if not _player.money_changed.is_connected(update_money_label):
			_player.money_changed.connect(update_money_label)
		menu_tile_limit = tiles.get_used_rect()
		_player.stats.in_menu = true
		_player.stats.hp = _player.stats.max_hp
		set_player_camera(_player)
		visible = true
		tiles.collision_enabled = true
		enable_doors()
		update_money_label(_player.stats.money)
		current_money.update_current_money(_player.stats.money)
		
func exit_scene(_player) -> void:
	disable_doors()
	visible = false
	tiles.collision_enabled = false
	#_player.stats.move_speed /= 2

func disable_doors() -> void:
	for child in get_children():
		if child is Door:
			child.disable_door()
			
func enable_doors() -> void:
	for child in get_children():
		if child is Door:
			child.enable_door()

func update_wave_label(wave_num: int) -> void:
	wave_label.text = "Current Wave: " + str(wave_num)
	
func update_money_label(amount) -> void:
	current_money.update_current_money(amount)
	
#func enable() -> void:
	#visible = true
	#enter_fight.monitoring = true
	#enter_shop.monitoring = true
	#tiles.collision_enabled = true
