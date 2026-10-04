class_name SkyShard extends Item

@export var fade_duration: float = 0.3

func launch(_target: Vector2) -> void:
	_landed = false
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_callback(func() -> void: _landed = true)
