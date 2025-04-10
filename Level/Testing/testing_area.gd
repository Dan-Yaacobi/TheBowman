extends Node2D

@onready var player: Player = $Player
const DEMO_ENEMY_2 = preload("res://Enemies/DemoEnemy/DemoEnemy2.tscn")
const DEMO_ENEMY_BOSS_2 = preload("res://Enemies/DemoEnemy/Boss2/DemoEnemyBoss2.tscn")
func _ready() -> void:

	var enemy: DemoEnemy = DEMO_ENEMY_2.instantiate()
	enemy.stats.shooter = true
	enemy.get_player(player)
	enemy.global_position = Vector2(0,-100)
	
	add_child(enemy)
