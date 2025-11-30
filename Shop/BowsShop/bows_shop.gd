class_name BowsShop extends Node2D

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var islands: Node2D = $Islands
@onready var pedestals: Node2D = $Pedestals
@onready var portals: Node2D = $Portals

var player: Player

func shop(b) -> void:
	if b is Player:
		EventBus.changed_scene.emit("Shop")

func set_scene(_player: Player) -> void:
		visible = true
		player = _player
		_player.global_position = player_spawn.global_position
		enable()
		
func disable() -> void:
	for portal in portals.get_children():
		portal.disable()
	for island in islands.get_children():
		island.disable()
	for pedestal in pedestals.get_children():
		pedestal.disable()

func enable() -> void:
	for portal in portals.get_children():
		portal.enable()
	for island in islands.get_children():
		island.enable()
	for pedestal in pedestals.get_children():
		pedestal.enable()
		
#func update_money(_val: int) -> void:
	#current_money.update_current_money(_val)

func exit_scene(_player) -> void:
	visible = false
	disable()
