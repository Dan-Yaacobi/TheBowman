class_name MenuArrow extends Node2D
## A big arrow shot from the viewer's side of the screen into a menu item.
## Flies along a perspective path (huge and close at the start, shrinking into
## the screen), sticks in the target, wobbles and throws splinters.

signal hit

## Depth the arrow starts at. Smaller = closer to the viewer = bigger at the start.
@export var start_depth: float = 0.14
## On-screen scale when it lands.
@export var end_scale: float = 4.5
## Squashes the shaft along its length, since the arrow is flying mostly into the screen.
@export var foreshorten: float = 0.62
@export var flight_time: float = 0.26
## How far the tip sinks into the target, in pixels.
@export var sink_depth: float = 7.0
@export var wobble_angle: float = 0.22
@export var wobble_time: float = 0.45
@export var wobble_speed: float = 46.0
## Seconds between afterimages while flying.
@export var ghost_interval: float = 0.016
@export var ghost_fade_time: float = 0.12

@onready var sprite: Sprite2D = $Sprite
@onready var splinters: CPUParticles2D = $Splinters

var _from: Vector2
var _to: Vector2
## Vanishing point of the perspective (screen center).
var _center: Vector2
var _ghost_timer: float = 0.0
var _flying: bool = false

func _ready() -> void:
	visible = false

## Shoots from `from` (usually just off the bottom of the screen) into `to`.
## Both in this node's parent's coordinates. Awaitable: returns on impact.
func fire(from: Vector2, to: Vector2, center: Vector2) -> void:
	_from = from
	_to = to
	_center = center
	rotation = (to - from).angle()
	splinters.direction = Vector2.LEFT
	visible = true
	_flying = true
	_set_progress(0.0)
	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, flight_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if not is_inside_tree():
		return
	_flying = false
	_impact()
	hit.emit()

## Fades the arrow out and frees it.
func vanish(time: float = 0.2) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, time)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	if not _flying:
		return
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_ghost_timer = ghost_interval
		_spawn_ghost()

## t: 0 = at the viewer, 1 = in the target. A straight 3D line seen in perspective:
## fast and huge up close, slowing and shrinking as it goes into the screen.
func _set_progress(t: float) -> void:
	var depth: float = lerpf(start_depth, 1.0, t)
	var near_point: Vector2 = (_from - _center) * start_depth
	var far_point: Vector2 = _to - _center
	position = _center + near_point.lerp(far_point, t) / depth
	var s: float = end_scale / depth
	scale = Vector2(s * foreshorten, s)

func _impact() -> void:
	scale = Vector2(end_scale * foreshorten, end_scale)
	position = _to + Vector2.RIGHT.rotated(rotation) * sink_depth
	splinters.restart()
	_spawn_ring()
	var tween: Tween = create_tween()
	tween.tween_method(_set_wobble, 0.0, 1.0, wobble_time)

func _set_wobble(t: float) -> void:
	var elapsed: float = t * wobble_time
	sprite.rotation = wobble_angle * sin(elapsed * wobble_speed) * exp(-elapsed * 9.0)

func _spawn_ghost() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.offset = sprite.offset
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.global_transform = sprite.global_transform
	ghost.modulate = Color(1.0, 0.95, 0.8, 0.35)
	parent.add_child(ghost)
	parent.move_child(ghost, get_index())
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, ghost_fade_time)
	tween.tween_callback(ghost.queue_free)

func _spawn_ring() -> void:
	var ring: ImpactRing = ImpactRing.new()
	ring.position = _to
	get_parent().add_child(ring)


## Expanding pale ring at the impact point.
class ImpactRing extends Node2D:
	const LIFETIME: float = 0.22
	const MAX_RADIUS: float = 46.0
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta / LIFETIME
		if _t >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var eased: float = 1.0 - pow(1.0 - _t, 3.0)
		var color: Color = Color(1.0, 0.93, 0.7, 1.0 - _t)
		draw_arc(Vector2.ZERO, MAX_RADIUS * eased, 0.0, TAU, 24, color, 4.0 * (1.0 - _t) + 1.0)
