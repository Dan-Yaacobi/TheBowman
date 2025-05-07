class_name TowerUpgradeMenu extends Node2D

var player: Player

@onready var shop_tower: ShopTower = $ShopTower
@onready var spawn_point: Node2D = $SpawnPoint
@onready var buy_tower: BuyTower = $BuyTower

func set_scene(_player: Player) -> void:
	if _player != null:
		visible = true
		player = _player
		player.set_camera(Rect2i(Vector2(-100000,-100000),Vector2(10000000,10000000)),16)
		shop_tower.set_player(player)
		shop_tower.set_upgrades()
		player.global_position = spawn_point.global_position
		spawn_point.visible = false
		buy_tower.set_player(_player)
		
func exit_scene(_player: Player) -> void:
	visible = false
	pass
	
