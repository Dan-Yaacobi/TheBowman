class_name MainMenu extends Node2D

#@onready var enter_fight: Area2D = $RightDoor/Enter
#@onready var enter_shop: Area2D = $LeftDoor/Enter
@onready var wave_label: Label = $CurrentWaves
#@onready var tiles: TileMapLayer = $Tiles
@onready var hard_mode_button: Button = $HardMode
@onready var normal_mode_button: Button = $NormalMode
@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var portals: Node2D = $Portals
@onready var islands: Node2D = $Islands
@onready var falling_death: FallingDeath = $FallingDeath

var menu_tile_limit: Rect2i
var tile_size: int = 16
var playground: PlayGround

var hard_mode: bool = false

func _ready() -> void:
	hard_mode_button.pressed.connect(activate_hard_mode)
	normal_mode_button.pressed.connect(activate_normal_mode)
	#enter_fight.body_entered.connect(start_fight)
	#enter_shop.body_entered.connect(shop)
	var game = get_parent()
	if game is Game:
		game.get_playground().wave_reset.connect(update_wave_label)

func activate_hard_mode() -> void:
	hard_mode = true
	playground.hard_mode = hard_mode
	
func activate_normal_mode() -> void:
	hard_mode = false
	playground.hard_mode = hard_mode
	
func start_fight(b) -> void:
	if b is Player:
		EventBus.changed_scene.emit("PlayGround")

func shop(b) -> void:
	if b is Player:
		EventBus.changed_scene.emit("Shop")

func set_player_camera(_player: Player) -> void:
	_player.set_camera(menu_tile_limit,tile_size)

func set_scene(_player: Player) -> void:
	if _player != null:
		_player.global_position = player_spawn.global_position
		#menu_tile_limit = tiles.get_used_rect()
		_player.stats.in_menu = true
		#set_player_camera(_player)
		visible = true
		#tiles.collision_enabled = true
		enable_islands_portals()
		falling_death.enabled()
		
func exit_scene(_player) -> void:
	disable_islands_portals()
	visible = false
	falling_death.disabled()
	#tiles.collision_enabled = false
	#_player.stats.move_speed /= 2

func disable_islands_portals() -> void:
	for portal in portals.get_children():
		portal.disable()
	for island in islands.get_children():
		island.disable()
		
func enable_islands_portals() -> void:
	for portal in portals.get_children():
		portal.enable()
	for island in islands.get_children():
		island.enable()

func update_wave_label(wave_num: int) -> void:
	wave_label.text = "Current Wave: " + str(wave_num)
	
#func enable() -> void:
	#visible = true
	#enter_fight.monitoring = true
	#enter_shop.monitoring = true
	#tiles.collision_enabled = true


func _on_falling_death_body_entered(body: Node2D) -> void:
	if body is Player:
		EventBus.changed_scene.emit("Menu")
	pass # Replace with function body.
