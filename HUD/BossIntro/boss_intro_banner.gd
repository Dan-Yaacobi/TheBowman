class_name BossIntroBanner extends CanvasLayer
## Full-screen boss intro: the screen darkens, cinema bars slide in, a red flash,
## "BOSS INCOMING" above the boss's name slamming in, then everything clears.
## Spawned by the arena/event that runs the intro; emits finished and frees itself.

signal finished

const TITLE_FONT_PATH: String = "res://Fonts/alagard.ttf"
const BAR_HEIGHT: float = 110.0
const ACCENT: Color = Color(0.85, 0.12, 0.1)
const TITLE_COLOR: Color = Color(1.0, 0.9, 0.75)

var boss_title: String = "Boss"
## Seconds the name holds on screen before everything clears.
var hold_time: float = 1.3

var _shade: ColorRect
var _top_bar: ColorRect
var _bottom_bar: ColorRect
var _flash: ColorRect
var _warning: Label
var _name: Label
var _rule: ColorRect

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var size: Vector2 = get_viewport().get_visible_rect().size
	_shade = _rect(Color(0, 0, 0, 0), Vector2.ZERO, size)
	_top_bar = _rect(Color.BLACK, Vector2(0, -BAR_HEIGHT), Vector2(size.x, BAR_HEIGHT))
	_bottom_bar = _rect(Color.BLACK, Vector2(0, size.y), Vector2(size.x, BAR_HEIGHT))
	_flash = _rect(Color(ACCENT, 0.0), Vector2.ZERO, size)
	_rule = _rect(ACCENT, Vector2(size.x / 2.0, size.y / 2.0 + 58.0), Vector2(0, 4))

	_warning = _label("BOSS INCOMING", 44, Color(1.0, 0.3, 0.22))
	_warning.position = Vector2(0, size.y / 2.0 - 120.0)
	_warning.size = Vector2(size.x, 50)
	_warning.modulate.a = 0.0

	_name = _label(boss_title.to_upper(), 104, TITLE_COLOR)
	_name.position = Vector2(0, size.y / 2.0 - 70.0)
	_name.size = Vector2(size.x, 130)
	_name.pivot_offset = _name.size / 2.0
	_name.modulate.a = 0.0
	_play(size)

func _play(size: Vector2) -> void:
	var intro: Tween = create_tween().set_parallel(true)
	intro.tween_property(_shade, "color:a", 0.45, 0.35)
	intro.tween_property(_top_bar, "position:y", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	intro.tween_property(_bottom_bar, "position:y", size.y - BAR_HEIGHT, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	intro.tween_property(_warning, "modulate:a", 1.0, 0.25).set_delay(0.2)
	await intro.finished
	if not is_inside_tree():
		return
	_warning_blink()
	# The name slams in from big to normal with a red flash and a shake.
	_name.scale = Vector2(2.6, 2.6)
	var slam: Tween = create_tween().set_parallel(true)
	slam.tween_property(_name, "modulate:a", 1.0, 0.12)
	slam.tween_property(_name, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await slam.finished
	if not is_inside_tree():
		return
	EventBus.camera_shake.emit(6.0, 12.0)
	_flash.color.a = 0.45
	var impact: Tween = create_tween().set_parallel(true)
	impact.tween_property(_flash, "color:a", 0.0, 0.4)
	impact.tween_property(_name, "scale", Vector2(1.08, 1.08), 0.06)
	impact.tween_property(_name, "scale", Vector2.ONE, 0.2).set_delay(0.06).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	impact.tween_property(_rule, "size:x", size.x * 0.5, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	impact.tween_property(_rule, "position:x", size.x * 0.25, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(hold_time, true, false, true).timeout
	if not is_inside_tree():
		return
	var outro: Tween = create_tween().set_parallel(true)
	outro.tween_property(_shade, "color:a", 0.0, 0.4)
	outro.tween_property(_top_bar, "position:y", -BAR_HEIGHT, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	outro.tween_property(_bottom_bar, "position:y", size.y, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	outro.tween_property(_name, "modulate:a", 0.0, 0.3)
	outro.tween_property(_warning, "modulate:a", 0.0, 0.3)
	outro.tween_property(_rule, "modulate:a", 0.0, 0.3)
	await outro.finished
	finished.emit()
	queue_free()

func _warning_blink() -> void:
	var blink: Tween = create_tween().set_loops(4)
	blink.tween_property(_warning, "modulate:a", 0.35, 0.15)
	blink.tween_property(_warning, "modulate:a", 1.0, 0.15)

func _rect(color: Color, position: Vector2, size: Vector2) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.color = color
	rect.position = position
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect

func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: Font = load(TITLE_FONT_PATH) as Font
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.02))
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_shadow_color", Color(ACCENT, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	add_child(label)
	return label
