class_name Helper extends Label

const BOB_HEIGHT: float = 4.0
const BOB_SPEED: float = 3.0
const FADE_DURATION: float = 0.3

var _base_y: float = 0.0
var _bobbing: bool = false
var _time: float = 0.0

func _ready() -> void:
	modulate.a = 0.0
	_base_y = position.y

func show_helper() -> void:
	_bobbing = false
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_callback(func(): _bobbing = true)

func hide_helper() -> void:
	_bobbing = false
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): position.y = _base_y)

func _process(delta: float) -> void:
	if _bobbing:
		_time += delta * BOB_SPEED
		position.y = _base_y + sin(_time) * BOB_HEIGHT
