class_name GlobalTextSpawner extends Node

var combat_text_scene = preload("res://General Nodes/CombatText/CombatText.tscn")

func spawn(_pos: Vector2, _text: String, _color: Color) -> void:
	var combat_text: CombatText = combat_text_scene.instantiate()
	get_tree().root.add_child(combat_text)
	combat_text.text = _text
	combat_text.set_text_color(_color)
	combat_text.start()
	var angle: float = randf_range(0, TAU)
	var radius: float = randf_range(0, 15)
	combat_text.set_position(_pos + Vector2(cos(angle), sin(angle)) * radius + Vector2(0, -20))
