class_name ThunderArrow extends Arrow

func _ready() -> void:
	cpu_particles.gravity = direction
	#hit_box.body_shape_entered.connect(hit_wall)
	if data.scale != 0:
		scale *= data.scale
	
func missed() -> void:
	if regular_shot:
		arrow_missed.emit()
	queue_free()
