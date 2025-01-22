extends Node2D

@onready var player: Player = $Player
const EVIL_BIRD = preload("res://Enemies/EvilBird/EvilBird.tscn")

func _ready() -> void:

	var enemy: Enemy = EVIL_BIRD.instantiate()
	enemy.get_player(player)
	enemy.global_position = Vector2(20,-120)
	add_child(enemy)
