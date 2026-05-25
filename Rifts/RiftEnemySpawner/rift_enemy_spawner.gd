class_name RiftEnemySpawner extends Node2D

signal enemy_spawned(enemy: Enemy)

@export var enemies: Enemies

@onready var rift: Rift = $".."

var rift_level: int

func spawn_enemy(level: int) -> void:
	print("level: ", level)
	#var cloud_factory: Callable = enemies.get_regular_cloud_factory()
	#var spider_factory: Callable = enemies.get_black_spider_factory()
	var bird_factory: Callable = enemies.get_red_evil_bird_factory()	
	#PlayerManager.player.spawn_handler.spawn_grounded_from_top(spider_factory,1,rift)
	#var red_apple_factory: Callable = enemies.get_red_apple_factory()
	var new_enemy: Enemy = PlayerManager.player.spawn_handler.spawn_from_top(bird_factory)	
	if new_enemy != null:
		enemy_spawned.emit(new_enemy)
