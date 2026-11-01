class_name LingeringEffect extends CPUParticles2D

## 0 = keeps emitting until stop() is called
@export var auto_stop_after: float = 0.0

var _stopping: bool = false

func _ready() -> void:
	emitting = true
	if auto_stop_after > 0.0:
		get_tree().create_timer(auto_stop_after, false).timeout.connect(stop)

# Frees itself once the last particles are gone, even if a one-shot already finished emitting
func stop() -> void:
	if _stopping:
		return
	_stopping = true
	emitting = false
	if not is_inside_tree():
		queue_free()
		return
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
