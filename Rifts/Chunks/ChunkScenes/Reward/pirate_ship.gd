extends Sprite2D

@onready var pirate: Pirate = $"../Pirate"

func _ready() -> void:
	if pirate:
		pirate.disappear.connect(sail_away)

func sail_away() -> void:
	var angle: float = deg_to_rad(randf_range(-30.0, 30.0))
	var direction: Vector2 = Vector2(sin(angle), -1.0).normalized()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + direction * 250.0, 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	tween.chain().tween_callback(queue_free)
