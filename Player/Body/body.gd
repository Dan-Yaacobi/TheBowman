class_name Body extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var current_animation: String
var last_animation: String

func change_animation(_animation: String) -> void:
	last_animation = current_animation
	if last_animation == "Dead":
		return
	animation_player.stop()
	animation_player.play(_animation)
	current_animation = _animation
	#if last_animation == "Walk" and current_animation == "Jump":
		#await animation_player.animation_finished
		#change_animation("Walk") 
	
	
func change_side(_side: bool) -> void:
	sprite.flip_h = _side

func reset_animations() -> void:
	last_animation = ""
	current_animation = ""
