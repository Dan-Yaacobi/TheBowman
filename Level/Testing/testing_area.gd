extends Node2D
const SPIDER_BOSS = preload("res://Enemies/Spider/SpiderBoss/SpiderBoss.tscn")
@onready var player: Player = $Player
const EVIL_BIRD = preload("res://Enemies/EvilBird/EvilBird.tscn")
const SPIDER = preload("res://Enemies/Spider/Spider.tscn")
const DEMO_ENEMY_BOSS = preload("res://Enemies/DemoEnemy/DemoEnemyBoss.tscn")
func _ready() -> void:

	var enemy: Enemy = DEMO_ENEMY_BOSS.instantiate()
	enemy.get_player(player)
	enemy.global_position = Vector2(0,-100)
	
	add_child(enemy)
