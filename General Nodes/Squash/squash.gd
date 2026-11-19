class_name Squash extends RefCounted
## Squash and stretch for any Node2D: snaps to a shape, then springs back with a little
## overshoot. Keeps the node's facing (negative x scale) and its resting size.
##   Squash.play(sprite, Vector2(1.3, 0.75))   # wide and short (a landing)
##   Squash.play(sprite, Vector2(0.8, 1.25))   # thin and tall (a jump)

const BASE_META: StringName = &"squash_base"
const TWEEN_META: StringName = &"squash_tween"

static func play(target: Node2D, shape: Vector2, duration: float = 0.22) -> void:
	if not is_instance_valid(target) or not target.is_inside_tree():
		return
	if not target.has_meta(BASE_META):
		target.set_meta(BASE_META, target.scale.abs())
	var base: Vector2 = target.get_meta(BASE_META)
	var previous: Tween = target.get_meta(TWEEN_META) if target.has_meta(TWEEN_META) else null
	if previous and previous.is_valid():
		previous.kill()
	var apply: Callable = func(t: float) -> void:
		if not is_instance_valid(target):
			return
		var size: Vector2 = base * Vector2.ONE.lerp(shape, t)
		target.scale = Vector2(size.x * (-1.0 if target.scale.x < 0.0 else 1.0), size.y)
	# Snap to the shape now so the peak always shows, even on a long frame.
	apply.call(1.0)
	var tween: Tween = target.create_tween()
	tween.tween_method(apply, 1.0, 0.0, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	target.set_meta(TWEEN_META, tween)

## Squash along a direction: thin along it, wide across it (a hit or a dash).
static func along(target: Node2D, direction: Vector2, amount: float = 0.25, duration: float = 0.22) -> void:
	var horizontal: bool = absf(direction.x) >= absf(direction.y)
	var shape: Vector2 = Vector2(1.0 - amount, 1.0 + amount) if horizontal else Vector2(1.0 + amount, 1.0 - amount)
	play(target, shape, duration)
