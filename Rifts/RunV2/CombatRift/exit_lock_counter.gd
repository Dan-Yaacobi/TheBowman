class_name ExitLockCounter extends Node2D
## Above a locked combat-rift exit: a skull and how many enemies are left.

const SKULL_PATH: String = "res://Player/HealthBar/Skull.png"

var _label: Label
var _count: int = -1


func _ready() -> void:
	z_index = 5
	var skull: Sprite2D = Sprite2D.new()
	skull.texture = load(SKULL_PATH)
	skull.position = Vector2(-7, 0)
	add_child(skull)
	_label = Label.new()
	_label.position = Vector2(2, -8)
	_label.size = Vector2(30, 16)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)
	_show()


func set_count(count: int) -> void:
	_count = count
	_show()


func _show() -> void:
	if _label:
		_label.text = "x %d" % _count if _count >= 0 else "x ?"
