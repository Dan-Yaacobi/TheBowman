class_name Body extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

func change_animation(_animation: String) -> void:
	animation_player.play(_animation)

func change_side(_side: bool) -> void:
	sprite.flip_h = _side
