extends CPUParticles2D

func _ready() -> void:
	emitting = false
	pass
	
func _process(_delta: float) -> void:
	if emitting:
		await get_tree().create_timer(0.2).timeout
		queue_free()
	pass
