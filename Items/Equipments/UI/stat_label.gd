class_name StatLabel extends Label

func set_label(_name: String, _amount: float = NAN) -> void:
	if is_nan(_amount):
		text = _name
	else:
		text = _name + ": " + str(_amount)

func set_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
