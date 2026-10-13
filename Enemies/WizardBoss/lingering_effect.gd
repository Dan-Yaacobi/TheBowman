class_name LingeringEffect extends CPUParticles2D

## 0 = keeps emitting until stop() is called
@export var auto_stop_after: float = 0.0

func _ready() -> void:
	emitting = true
	if auto_stop_after > 0.0:
		get_tree().create_timer(auto_stop_after, false).timeout.connect(stop)

func stop() -> void:
	if not emitting:
		return
	emitting = false
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
