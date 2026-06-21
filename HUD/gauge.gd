class_name Gauge extends TextureProgressBar

signal gauge_ready
@onready var sprite: Sprite2D = $Sprite2D

var _tween: Tween

func _ready() -> void:
	hide()
	EventBus.setup_gauge.connect(setup)

func setup(_max_value: int, _texture: Texture = null, _tint: Color = Color.WHITE) -> void:
	max_value = _max_value
	value = 0
	sprite.texture = _texture
	tint_progress = _tint
	show()
	gauge_ready.emit()
	EventBus.fill_gauge.connect(fill)
	EventBus.request_gauge.connect(drain)

func disable() -> void:
	value = 0
	hide()
	EventBus.fill_gauge.disconnect(fill)
	EventBus.request_gauge.disconnect(drain)
	
func fill(_amount: float) -> void:
	value = min(value + _amount, max_value)

func drain(_only_full: bool) -> void:
	var _amount: int = int(value)
	if _amount <= 0:
		return
		
	if _only_full and _amount < max_value:
		return
		
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", 0, 0.3)
	EventBus.use_gauge.emit(_amount)
