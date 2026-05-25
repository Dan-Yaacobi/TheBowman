class_name ArrowSprite extends Sprite2D

var hit: bool = false

func _process(delta: float) -> void:
	if hit:
		set_process(false)
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		await tween.finished
		queue_free()
	pass
