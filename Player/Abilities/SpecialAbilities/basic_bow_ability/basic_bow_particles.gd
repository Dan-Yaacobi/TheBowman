extends CPUParticles2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	audio_stream_player_2d.pitch_scale = randf_range(0.5,1.5)
	audio_stream_player_2d.play()
	
