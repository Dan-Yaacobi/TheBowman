class_name BowDrawVfx extends Node2D
## Bow draw effects at the arrowhead (same warm-steel family as the sword slashes):
## air pulled in from all around while drawing (follows draw progress), a glint at full draw,
## and a pop on release whose size follows the shot's power (biggest on a perfect shot).
## Created by PlayerMainHand; sits at the arrowhead in hand space so it turns with the aim.

const GATHER_PATH: String = "res://Player/Player2.0/Sprites/BowVfx/DrawAirGather.png"
const GLINT_PATH: String = "res://Player/Player2.0/Sprites/BowVfx/FullDrawGlint.png"
const POP_PATH: String = "res://Player/Player2.0/Sprites/BowVfx/ReleasePop.png"
## Arrowhead position in the main hand's local space.
const ARROW_TIP: Vector2 = Vector2(22, 1)
const GATHER_FRAMES: int = 12
const GLINT_FRAMES: int = 4
const POP_FRAMES: int = 7
const FRAME_TIME: float = 0.06

## Pop size on the weakest shot / a full draw.
@export var pop_min_scale: float = 0.35
@export var pop_full_scale: float = 1.0
## Extra size on a perfect shot.
@export var pop_perfect_mult: float = 1.35

var main_hand: PlayerMainHand
var _gather: Sprite2D
var _glint: Sprite2D
var _pop: Sprite2D
var _glint_time: float = -1.0
var _pop_time: float = -1.0

func _ready() -> void:
	position = ARROW_TIP
	z_index = 3
	# hframes, vframes, point in the frame that sits on the arrowhead
	_gather = _make_sprite(GATHER_PATH, 4, 3, Vector2(28, 28.5))
	_glint = _make_sprite(GLINT_PATH, 2, 2, Vector2(10, 10.5))
	_pop = _make_sprite(POP_PATH, 3, 3, Vector2(28, 23.5))
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
	# Gather: frame follows the draw and holds its last frame (the bright core) at full draw.
	var drawing: bool = main_hand.is_drawing()
	_gather.visible = drawing
	if drawing:
		_gather.frame = clampi(int(main_hand.shot_power * (GATHER_FRAMES - 1)), 0, GATHER_FRAMES - 1)
	_glint_time = _step_one_shot(_glint, _glint_time, GLINT_FRAMES, delta)
	_pop_time = _step_one_shot(_pop, _pop_time, POP_FRAMES, delta)

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
	var power: float = clampf(main_hand.shot_power, 0.0, 1.0)
	if power <= 0.0:
		return
	var size: float = lerpf(pop_min_scale, pop_full_scale, power)
	if power >= 1.0:
		size *= pop_perfect_mult
	_pop.scale = Vector2(size, size)
	_pop_time = 0.0
