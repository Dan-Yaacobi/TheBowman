class_name Gauge extends TextureProgressBar

signal gauge_ready
@onready var sprite: Sprite2D = $Sprite2D
@onready var aura: ColorRect = $Aura

# Room around the bar for flames. Keep larger than the shader's reach.
@export var aura_side_margin: float = 8.0
@export var aura_top_margin: float = 16.0

var _tween: Tween
var charge_color: Color
var charge_type: PlayerBody.Charges
var gauge_tween: Tween

func _ready() -> void:
	hide()
	EventBus.setup_gauge.connect(setup)
	EventBus.disable_gauge.connect(disable)
	aura.show_behind_parent = true
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(_max_value: int, _texture: Texture = null, _tint: Color = Color.WHITE, _charge_color: Color = Color.WHITE, _charge_type: PlayerBody.Charges = PlayerBody.Charges.BLOOD) -> void:
	max_value = _max_value
	value = 0
	sprite.texture = _texture
	tint_progress = _tint
	charge_color = _charge_color
	charge_type = _charge_type
	_layout_aura()
	var mat: ShaderMaterial = aura.material as ShaderMaterial
	mat.set_shader_parameter("glow_color", charge_color)
	mat.set_shader_parameter("strength", 0.0)
	show()
	gauge_ready.emit()
	EventBus.fill_gauge.connect(fill)
	EventBus.request_gauge.connect(drain)

func disable() -> void:
	value = 0
	if gauge_tween:
		gauge_tween.kill()
	(aura.material as ShaderMaterial).set_shader_parameter("strength", 0.0)
	hide()
	EventBus.fill_gauge.disconnect(fill)
	EventBus.request_gauge.disconnect(drain)

func fill(_amount: float) -> void:
	var was_full: bool = value >= max_value
	value = min(value + _amount, max_value)
	if not was_full and value >= max_value:
		_set_glow(1.0)

func drain(_only_full: bool = true) -> void:
	var _amount: int = int(value)
	if _amount <= 0:
		return

	if _only_full and _amount < max_value:
		return

	_set_glow(0.0)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", 0, 0.3)
	EventBus.charge_gauge.emit(_amount, charge_color, charge_type)

func _layout_aura() -> void:
	# Size the aura to the bar plus margins, and tell the shader where the bar is inside it.
	var offset: Vector2 = Vector2(aura_side_margin, aura_top_margin)
	aura.position = -offset
	aura.size = size + Vector2(aura_side_margin * 2.0, aura_top_margin + aura_side_margin)
	var mat: ShaderMaterial = aura.material as ShaderMaterial
	mat.set_shader_parameter("rect_size", aura.size)
	mat.set_shader_parameter("bar_min", offset)
	mat.set_shader_parameter("bar_max", offset + size)

func _set_glow(target: float) -> void:
	if gauge_tween:
		gauge_tween.kill()
	gauge_tween = create_tween()
	gauge_tween.tween_property(aura.material, "shader_parameter/strength", target, 0.2)
