class_name BowsShop extends GameWorld

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var islands: Node2D = $Islands
@onready var pedestals: Node2D = $Pedestals
@onready var portals: Node2D = $Portals
@onready var falling_death: FallingDeath = $FallingDeath

var player: Player

func _ready() -> void:
	pass

func spawn_position() -> Vector2:
	return player_spawn.global_position
	
	#falling_death.body_entered.connect(to_menu)
	#
#func to_menu(b) -> void:
	#if b is Player:
		#EventBus.changed_scene.emit("Menu")
#
#func set_scene(_player: Player) -> void:
		#visible = true
		#player = _player
		#_player.global_position = player_spawn.global_position
		#enable()
		#falling_death.enabled()
		#
#func disable() -> void:
	#for portal in portals.get_children():
		#portal.disable()
	#for island in islands.get_children():
		#island.disable()
	#for pedestal in pedestals.get_children():
		#pedestal.disable()
#
#func enable() -> void:
	#for portal in portals.get_children():
		#portal.enable()
	#for island in islands.get_children():
		#island.enable()
	#for pedestal in pedestals.get_children():
		#pedestal.enable()
		#
##func update_money(_val: int) -> void:
	##current_money.update_current_money(_val)
#
#func exit_scene(_player) -> void:
	#visible = false
	#disable()
	#falling_death.disabled()
