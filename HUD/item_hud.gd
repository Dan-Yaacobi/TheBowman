@tool
class_name ItemHud extends HBoxContainer

@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		if is_node_ready():
			_apply_visuals()
@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			_apply_visuals()

@export_group("Feedback")
## How big the icon + count jump on gain, then ease back to normal.
@export var gain_scale: float = 1.3
## How small they dip on loss.
@export var loss_scale: float = 0.85
@export var pop_duration: float = 0.18
## Above 1.0 brightens the whole item for a moment.
@export var gain_flash: Color = Color(1.6, 1.6, 1.6, 1.0)
@export var loss_flash: Color = Color(1.0, 0.4, 0.4, 1.0)
## How long the number takes to count to its new value.
@export var count_duration: float = 0.25

@onready var amount: Label = $Amount
@onready var texture_rect: TextureRect = $TextureRect

var _current: int = 0
var _displayed: int = 0
var _pop_tween: Tween
var _count_tween: Tween

func _ready() -> void:
	_apply_visuals()
	_show_value(float(_current))

func _apply_visuals() -> void:
	texture_rect.texture = texture
	amount.add_theme_color_override(&"font_color", text_color)

## Pass animate = false when loading saved values so the HUD doesn't pop on start.
func set_amount(new_amount: int, animate: bool = true) -> void:
	var gained: bool = new_amount > _current
	_current = new_amount
	if not animate or Engine.is_editor_hint():
		_stop_tweens()
		scale = Vector2.ONE
		modulate = Color.WHITE
		_show_value(float(new_amount))
		return
	_roll_count(new_amount)
	_play_pop(gained)

func _roll_count(target: int) -> void:
	if _count_tween:
		_count_tween.kill()
	_count_tween = create_tween()
	_count_tween.tween_method(_show_value, float(_displayed), float(target), count_duration)

func _play_pop(gained: bool) -> void:
	if _pop_tween:
		_pop_tween.kill()
	pivot_offset = size / 2.0
	scale = Vector2.ONE * (gain_scale if gained else loss_scale)
	modulate = gain_flash if gained else loss_flash
	_pop_tween = create_tween().set_parallel(true)
	_pop_tween.tween_property(self, "scale", Vector2.ONE, pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(self, "modulate", Color.WHITE, pop_duration * 2.0)

func _show_value(value: float) -> void:
	_displayed = roundi(value)
	amount.text = "x" + str(_displayed)

func _stop_tweens() -> void:
	if _pop_tween:
		_pop_tween.kill()
	if _count_tween:
		_count_tween.kill()
