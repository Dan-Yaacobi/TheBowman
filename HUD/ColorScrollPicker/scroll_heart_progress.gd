class_name ScrollHeartProgress extends HBoxContainer
## Row under the scroll cards: one pip per scroll toward the next heart container, then a heart.
## The pip this pick fills pulses; when this pick completes the set, the heart pulses too.

const HEART_FULL_PATH: String = "res://Player/HealthBar/Heart2.png"
const HEART_EMPTY_PATH: String = "res://Player/HealthBar/EmptyHeart2.png"

@export var pip_size: Vector2 = Vector2(14, 14)
@export var heart_size: Vector2 = Vector2(32, 32)
@export var filled_color: Color = Color(1.0, 0.85, 0.45)
@export var empty_color: Color = Color(0.2, 0.17, 0.13, 0.8)
@export var next_color: Color = Color(1.0, 0.95, 0.75)

var _pips: Array[ColorRect] = []
var _heart: TextureRect
var _label: Label
var _pulse: Tween

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", 6)

## filled: scrolls already counted toward the next heart. needed: scrolls per heart.
func setup(filled: int, needed: int) -> void:
	_build(needed)
	var completes: bool = filled + 1 >= needed
	for i: int in _pips.size():
		_pips[i].color = filled_color if i < filled else empty_color
		_pips[i].modulate = Color.WHITE
	_heart.texture = load(HEART_FULL_PATH if completes else HEART_EMPTY_PATH)
	_heart.modulate = Color.WHITE
	_label.text = "This pick: +1 Heart!" if completes else "+1 Heart every %d scrolls" % needed
	if _pulse:
		_pulse.kill()
	if filled < _pips.size():
		var next_pip: ColorRect = _pips[filled]
		next_pip.color = next_color
		_pulse = create_tween().set_loops()
		_pulse.tween_property(next_pip, "modulate:a", 0.35, 0.45).set_trans(Tween.TRANS_SINE)
		_pulse.parallel().tween_property(_heart, "modulate", Color(1.4, 1.4, 1.4) if completes else Color.WHITE, 0.45)
		_pulse.tween_property(next_pip, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
		_pulse.parallel().tween_property(_heart, "modulate", Color.WHITE, 0.45)

func _build(needed: int) -> void:
	if _pips.size() == needed and _heart:
		return
	for child: Node in get_children():
		child.queue_free()
	_pips.clear()
	for i: int in needed:
		var pip: ColorRect = ColorRect.new()
		pip.custom_minimum_size = pip_size
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(pip)
		_pips.append(pip)
	var arrow: Label = Label.new()
	arrow.text = ">"
	arrow.theme_type_variation = &"DimLabel"
	add_child(arrow)
	_heart = TextureRect.new()
	_heart.custom_minimum_size = heart_size
	_heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_heart)
	_label = Label.new()
	add_child(_label)
