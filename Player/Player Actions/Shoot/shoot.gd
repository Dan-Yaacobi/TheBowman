class_name ShootAction extends Node2D

@onready var player: Player = $".."
@onready var arrow_shot: AudioStreamPlayer2D = $ArrowShot
@onready var arrow_hit: AudioStreamPlayer2D = $ArrowHit


func shoot(_mouse_pos: Vector2) -> void:
	for i in player.get_current_weapon().weapon_data.shots:
		var offset: bool = false
		if i > 0:
			offset = true
		player.get_current_weapon().shoot(offset,false)
	player.body.change_side(_mouse_pos.x < player.global_position.x)
	arrow_shot.play()
	pass

func mega_shot(_mouse_pos: Vector2) -> void:
	for i in player.get_current_weapon().weapon_data.shots:
		var offset: bool = false
		if i > 0:
			offset = true
		player.get_current_weapon().shoot(offset,true)
	player.body.change_side(_mouse_pos.x < player.global_position.x)
	arrow_shot.play()
	pass
	
func arrow_hit_sound() -> void:
	arrow_hit.pitch_scale = randf_range(0.4,1.4)
	arrow_hit.play()
