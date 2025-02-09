extends Node2D

@onready var player: Player = $Player
const EVIL_BIRD = preload("res://Enemies/EvilBird/EvilBird.tscn")
const SPIDER = preload("res://Enemies/Spider/Spider.tscn")
func _ready() -> void:

	var enemy: Enemy = SPIDER.instantiate()
	enemy.get_player(player)
	enemy.global_position = Vector2(player.global_position.x,-120)
	
	add_child(enemy)
