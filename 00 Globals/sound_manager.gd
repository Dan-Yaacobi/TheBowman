extends Node2D

@onready var arrow_shot: AudioStreamPlayer2D = $ArrowShot
@onready var arrow_hit: AudioStreamPlayer2D = $ArrowHit

func _ready() -> void:
	EventBus.arrow_hit_sound.connect(arrow_hit_sound)
	EventBus.arrow_shot_sound.connect(arrow_shot_sound)

func arrow_hit_sound() -> void:
	arrow_hit.pitch_scale = randf_range(0.4,1.4)
	arrow_hit.play()

func arrow_shot_sound() -> void:
	arrow_shot.play()
