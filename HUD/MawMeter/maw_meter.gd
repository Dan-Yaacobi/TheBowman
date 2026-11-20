class_name MawMeter extends Control
## The Maw's stage name, soul count toward the next stage and a progress bar, in the HUD
## under the color levels. Hidden unless the Maw is equipped.

const BAR_SIZE: Vector2 = Vector2(80, 5)
const BAR_TOP: float = 16.0
const PULSE_SCALE: float = 0.15
const PULSE_DECAY: float = 4.0

var _label: Label
var _fill: float = 0.0
var _color: Color = Color.WHITE
var _pulse: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.position = Vector2.ZERO
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_child(_label)
	hide()
	EventBus.maw_souls_changed.connect(_on_event_bus_maw_souls_changed)
	EventBus.maw_unequipped.connect(hide)

func _on_event_bus_maw_souls_changed(stage_name: String, souls: int, floor_souls: int, next_souls: int, color: Color, ate_soul: bool) -> void:
	_color = color
	_label.add_theme_color_override("font_color", color)
	if next_souls < 0:
		_label.text = "The Maw: %s  %d" % [stage_name, souls]
		_fill = 1.0
	else:
		_label.text = "The Maw: %s  %d/%d" % [stage_name, souls, next_souls]
		_fill = clampf(float(souls - floor_souls) / float(maxi(next_souls - floor_souls, 1)), 0.0, 1.0)
	if ate_soul:
		_pulse = 1.0
	show()
	queue_redraw()

func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta * PULSE_DECAY, 0.0)
		var bump: float = 1.0 + PULSE_SCALE * _pulse
		_label.scale = Vector2.ONE * bump
		queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2(0, BAR_TOP), BAR_SIZE)
	draw_rect(rect.grow(1.0), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(rect.position, Vector2(BAR_SIZE.x * _fill, BAR_SIZE.y)), _color.lightened(0.4 * _pulse))
