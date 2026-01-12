class_name MainMenu extends GameWorld

#@onready var enter_fight: Area2D = $RightDoor/Enter
#@onready var enter_shop: Area2D = $LeftDoor/Enter
@onready var wave_label: Label = $CurrentWaves
#@onready var tiles: TileMapLayer = $Tiles
@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var portals: Node2D = $Portals
@onready var islands: Node2D = $Islands
@onready var falling_death: FallingDeath = $FallingDeath
#
#var menu_tile_limit: Rect2i
#var tile_size: int = 16
#var playground: PlayGround


func _ready() -> void:
	pass

func spawn_position() -> Vector2:
	return player_spawn.global_position
#func start_fight(b) -> void:
	#if b is Player:
		#EventBus.changed_scene.emit("PlayGround")
#
#func shop(b) -> void:
	#if b is Player:
		#EventBus.changed_scene.emit("Shop")
#
#func set_scene(_player: Player) -> void:
	#if _player != null:
		#_player.global_position = player_spawn.global_position
		##menu_tile_limit = tiles.get_used_rect()
		#_player.stats.rift_level = 0
		#_player.stats.in_menu = true
		##set_player_camera(_player)
		#visible = true
		##tiles.collision_enabled = true
		##enable_islands_portals()
		#falling_death.enabled()
		#
#func exit_scene(_player) -> void:
	##disable_islands_portals()
	#visible = false
	#falling_death.disabled()
	##tiles.collision_enabled = false
	##_player.stats.move_speed /= 2

#func disable_islands_portals() -> void:
	#for portal in portals.get_children():
		#portal.disable()
	#for island in islands.get_children():
		#island.disable()
		#
#func enable_islands_portals() -> void:
	#for portal in portals.get_children():
		#portal.enable()
	#for island in islands.get_children():
		#island.enable()

#func update_wave_label(wave_num: int) -> void:
	#wave_label.text = "Current Wave: " + str(wave_num)
	#
#func enable() -> void:
	#visible = true
	#enter_fight.monitoring = true
	#enter_shop.monitoring = true
	#tiles.collision_enabled = true


func _on_falling_death_body_entered(body: Node2D) -> void:
	if body is Player:
		EventBus.changed_scene.emit("Menu")
	pass # Replace with function body.
