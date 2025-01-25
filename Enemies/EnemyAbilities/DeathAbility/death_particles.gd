extends CPUParticles2D

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	#finished.connect(clear)
	audio_stream_player_2d.play()
	audio_stream_player_2d.finished.connect(clear)
	
func clear() -> void:
	queue_free()
