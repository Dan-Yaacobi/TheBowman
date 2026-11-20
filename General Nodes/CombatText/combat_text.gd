class_name CombatText extends Node2D

const COMBAT_TEXT = preload("res://General Nodes/CombatText/CombatText.tscn")

@onready var combat_text: Label = $CombatText

## Upward launch speed (px/s); the text arcs up and falls back under gravity.
@export var launch_speed: float = 75.0
## Max sideways drift (px/s), random direction per text.
@export var side_speed: float = 30.0
@export var gravity: float = 190.0
## Peak scale of the pop, relative to the resting scale.
@export var pop_scale: float = 1.7
## Seconds the text stays fully visible before fading.
@export var hold_time: float = 0.45
@export var fade_time: float = 0.3

var text: String
var appear: bool = false
var velocity: Vector2 = Vector2.ZERO
var target_color: Color = Color.WHITE

func _ready() -> void:
	scale *= randf_range(0.8,1.2)
	visible = false

func _process(delta: float) -> void:
	if appear:
		position += velocity * delta
		velocity.y += gravity * delta

func start() -> void:
	appear = true
	visible = true
	set_text(text)
	# Center the label on the node so the pop scales from the middle, not the top-left.
	combat_text.reset_size()
	combat_text.position = -combat_text.size * combat_text.scale * 0.5
	velocity = Vector2(randf_range(-side_speed, side_speed), -launch_speed)
	_pop()

## Snaps in small, overshoots big, settles; flashes white into its color, then fades out.
func _pop() -> void:
	var rest: Vector2 = scale
	scale = rest * 0.3
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", rest * pop_scale, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", rest, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_method(_apply_color, Color.WHITE, target_color, 0.14)
	tween.tween_interval(hold_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.parallel().tween_property(self, "scale", rest * 0.6, fade_time)
	tween.tween_callback(queue_free)
	_apply_color(Color.WHITE)

func crit() -> void:
	pass

func set_text(_text: String) -> void:
	combat_text.text = _text

func set_text_color(color: Color) -> void:
	if color:
		target_color = color
		_apply_color(color)

func _apply_color(color: Color) -> void:
	combat_text.add_theme_color_override("font_color", color)
