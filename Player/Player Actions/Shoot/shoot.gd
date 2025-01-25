class_name ShootAction extends Node2D

@onready var player: Player = $".."
@onready var arrow_shot: AudioStreamPlayer2D = $ArrowShot
@onready var arrow_hit: AudioStreamPlayer2D = $ArrowHit


func shoot(_mouse_pos: Vector2) -> void:
	player.get_current_weapon().shoot()
	player.body.change_side(_mouse_pos.x < player.global_position.x)
	arrow_shot.play()
	pass
	
func arrow_hit_sound() -> void:
	arrow_hit.pitch_scale = randf_range(0.4,1.4)
	arrow_hit.play()
