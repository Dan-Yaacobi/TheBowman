extends CPUParticles2D

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	audio_stream_player_2d.play()
	emitting = true
	audio_stream_player_2d.finished.connect(queue_free)
