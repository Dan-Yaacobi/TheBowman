extends Node2D

@onready var player: Player = $Player

const DEMO_ENEMY_BOSS_2 = preload("res://Enemies/DemoEnemy/Boss2/DemoEnemyBoss2.tscn")
func _ready() -> void:

	var enemy: Enemy = DEMO_ENEMY_BOSS_2.instantiate()
	enemy.get_player(player)
	enemy.global_position = Vector2(0,-100)
	
	add_child(enemy)
