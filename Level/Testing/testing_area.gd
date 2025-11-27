extends Node2D

const DEMO_ENEMY_2 = preload("res://Enemies/DemoEnemy/DemoEnemy.tscn")
@onready var hud: HUD = $Hud
var player: Player
func _ready() -> void:
	player = PlayerManager.player
	player.mana_bar = hud.get_mana_bar()
	player.health_bar = hud.get_health_bar()
	player.total_buffs = hud.get_total_buffs()
	player.special_ability_cd = hud.get_special_ability_cd()
	player.global_position = Vector2.ZEROd

	add_child(player)
	##treasure_chest.set_player(player)
	##return
	#var enemy: DemoEnemy = DEMO_ENEMY_2.instantiate()
	##enemy.stats.shooter = true
	#enemy.get_player(player)
	#enemy.global_position = Vector2(0,-100)
	#
	#add_child(enemy)
