extends CPUParticles2D


func _ready() -> void:
	emitting = true
	
func clear() -> void:
	queue_free()

func _on_finished() -> void:
	queue_free()
