class_name ShootAction extends Node2D

@onready var player: Player = $".."
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


func shoot(_mouse_pos: Vector2) -> void:
	player.get_current_weapon().shoot()
	player.body.change_side(_mouse_pos.x < player.global_position.x)
	audio_stream_player.play()
	pass
	
	
