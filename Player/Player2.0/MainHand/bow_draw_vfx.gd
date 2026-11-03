class_name BowDrawVfx extends Node2D
## Bow draw effects at the arrowhead (same warm-steel family as the sword slashes):
## motes gathering while drawing (follows draw progress), a glint at full draw, a streak on a perfect release.
## Created by PlayerMainHand; sits at the arrowhead in hand space so it turns with the aim.

const CHARGE_PATH: String = "res://Player/Player2.0/Sprites/BowVfx/DrawCharge.png"
const GLINT_PATH: String = "res://Player/Player2.0/Sprites/BowVfx/FullDrawGlint.png"
const RELEASE_PATH: String = "res://Player/Player2.0/Sprites/BowVfx/PerfectRelease.png"
## Arrowhead position in the main hand's local space.
const ARROW_TIP: Vector2 = Vector2(22, 1)
const FRAME_TIME: float = 0.06

var main_hand: PlayerMainHand
var _charge: Sprite2D
var _glint: Sprite2D
var _release: Sprite2D
var _glint_time: float = -1.0
var _release_time: float = -1.0

func _ready() -> void:
	position = ARROW_TIP
	z_index = 3
	# hframes, vframes, frame count, point in the frame that sits on the arrowhead
	_charge = _make_sprite(CHARGE_PATH, 4, 3, Vector2(13, 13.5))
	_glint = _make_sprite(GLINT_PATH, 2, 2, Vector2(10, 10.5))
	_release = _make_sprite(RELEASE_PATH, 3, 3, Vector2(1, 3.5))
	main_hand.max_pull_state.max_pull.connect(_on_max_pull)
	main_hand.release.connect(_on_release)

func _make_sprite(path: String, h: int, v: int, anchor: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load(path)
	sprite.hframes = h
	sprite.vframes = v
	sprite.centered = false
	sprite.offset = -anchor
	sprite.visible = false
	add_child(sprite)
	return sprite

func _process(delta: float) -> void:
	# Charge: frame follows the draw, holds its last frame at full draw.
	var drawing: bool = main_hand.is_drawing()
	_charge.visible = drawing
	if drawing:
		var last: int = 10
		_charge.frame = clampi(int(main_hand.shot_power * last), 0, last)
	_glint_time = _step_one_shot(_glint, _glint_time, 4, delta)
	_release_time = _step_one_shot(_release, _release_time, 7, delta)

func _step_one_shot(sprite: Sprite2D, time: float, frames: int, delta: float) -> float:
	if time < 0.0:
		return time
	var frame: int = int(time / FRAME_TIME)
	if frame >= frames:
		sprite.visible = false
		return -1.0
	sprite.visible = true
	sprite.frame = frame
	return time + delta

func _on_max_pull() -> void:
	_glint_time = 0.0

func _on_release() -> void:
	_glint_time = -1.0
	_glint.visible = false
	if main_hand.shot_power >= 1.0:
		_release_time = 0.0
