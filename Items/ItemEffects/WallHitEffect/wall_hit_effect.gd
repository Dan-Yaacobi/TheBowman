extends CPUParticles2D

func _ready() -> void:
	finished.connect(clear)
	
func clear() -> void:
	queue_free()
