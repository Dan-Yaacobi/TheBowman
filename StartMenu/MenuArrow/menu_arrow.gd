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
## Faint afterimages left along the flight. Off for arrows shot into the scenery: their
## path curves away from the shaft, so the copies read as a second arrow beside it.
@export var afterimages: bool = true
## Seconds between afterimages while flying.
@export var ghost_interval: float = 0.016
@export var ghost_fade_time: float = 0.12
## Size of the pale ring at the impact point.
@export var ring_radius: float = 46.0
## How far past its aim point (in flight lengths) a missed arrow keeps going before it's gone.
## Kept short: further on, shots near the top would slide off the screen instead of receding.
@export var miss_distance: float = 1.2
@export var miss_time: float = 0.35

@onready var sprite: Sprite2D = $Sprite
@onready var splinters: CPUParticles2D = $Splinters

var _from: Vector2
var _to: Vector2
## Vanishing point of the perspective (screen center).
var _center: Vector2
var _ghost_timer: float = 0.0
var _flying: bool = false
## Optional moving target: the aim point follows it through the flight.
var _track: Node2D
var _track_offset: Vector2
## Extra shrink on top of perspective, for a missed arrow receding into the distance.
var _recede: float = 1.0

func _ready() -> void:
	visible = false

## Shoots from `from` (usually just off the bottom of the screen) into `to`.
## Both in this node's parent's coordinates. Awaitable: returns on impact.
## With `track`, `to` is a point in `track`'s local space and the arrow homes in on it as it moves.
func fire(from: Vector2, to: Vector2, center: Vector2, track: Node2D = null) -> void:
	_track = track
	_track_offset = to
	_from = from
	_to = _tracked_point() if track else to
	_center = center
	rotation = (_to - from).angle()
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

## Like fire(), but the arrow hits nothing: it passes its aim point and keeps going
## into the distance, shrinking toward its vanishing point, then frees itself.
func fly_off(from: Vector2, to: Vector2, center: Vector2) -> void:
	_track = null
	_from = from
	_to = to
	_center = center
	rotation = (to - from).angle()
	visible = true
	_flying = true
	_set_progress(0.0)
	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, flight_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Past the aim point it slows and fades: afterimages would linger as a second arrow.
	tween.tween_callback(func() -> void: _flying = false)
	tween.tween_method(_set_progress, 1.0, miss_distance, miss_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_recede", 0.0, miss_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, miss_time * 0.5).set_delay(miss_time * 0.5)
	await tween.finished
	if not is_inside_tree():
		return
	_spawn_ring(position, 0.25)
	queue_free()

## Fades the arrow out and frees it.
func vanish(time: float = 0.2) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, time)
	tween.tween_callback(queue_free)

## Stays stuck where it landed (moving with its new parent), then fades after `linger` seconds.
func stick(new_parent: Node, linger: float) -> void:
	reparent(new_parent)
	var tween: Tween = create_tween()
	tween.tween_interval(linger)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

## Knocked loose: tumbles away from `push` and falls out of sight.
func drop(push: Vector2, fall_distance: float = 120.0) -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "position:x", position.x + push.x, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + push.y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + push.y + fall_distance, 0.52).set_delay(0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", rotation + signf(push.x + 0.01) * TAU * 1.5, 0.7)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.45)
	tween.chain().tween_callback(queue_free)

## Sucked into `point` (in the parent's coordinates) and gone.
func swallow(point: Vector2, time: float = 0.35) -> void:
	var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", point, time)
	tween.tween_property(self, "scale", Vector2.ZERO, time)
	tween.tween_property(self, "rotation", rotation + TAU, time).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(queue_free)

func _process(delta: float) -> void:
	if not _flying or not afterimages:
		return
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_ghost_timer = ghost_interval
		_spawn_ghost()

## t: 0 = at the viewer, 1 = in the target. A straight 3D line seen in perspective:
## fast and huge up close, slowing and shrinking as it goes into the screen.
func _set_progress(t: float) -> void:
	if _track:
		if is_instance_valid(_track):
			_to = _tracked_point()
		else:
			_track = null
	var depth: float = lerpf(start_depth, 1.0, t)
	var near_point: Vector2 = (_from - _center) * start_depth
	var far_point: Vector2 = _to - _center
	position = _center + near_point.lerp(far_point, t) / depth
	var s: float = end_scale / depth * _recede
	scale = Vector2(s * foreshorten, s)

func _impact() -> void:
	scale = Vector2(end_scale * foreshorten, end_scale)
	position = _to + Vector2.RIGHT.rotated(rotation) * sink_depth
	splinters.restart()
	_spawn_ring(_to, 1.0)
	var tween: Tween = create_tween()
	tween.tween_method(_set_wobble, 0.0, 1.0, wobble_time)

func _tracked_point() -> Vector2:
	return get_parent().to_local(_track.to_global(_track_offset))

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
	ghost.modulate = Color(1.0, 0.95, 0.8, 0.35)
	parent.add_child(ghost)
	parent.move_child(ghost, get_index())
	ghost.global_transform = sprite.global_transform
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, ghost_fade_time)
	tween.tween_callback(ghost.queue_free)

func _spawn_ring(at: Vector2, size: float) -> void:
	var ring: ImpactRing = ImpactRing.new()
	ring.position = at
	ring.max_radius = ring_radius * size
	get_parent().add_child(ring)


## Expanding pale ring at the impact point.
class ImpactRing extends Node2D:
	const LIFETIME: float = 0.22
	var max_radius: float = 46.0
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
		var width: float = (4.0 * (1.0 - _t) + 1.0) * clampf(max_radius / 46.0, 0.25, 1.0)
		draw_arc(Vector2.ZERO, max_radius * eased, 0.0, TAU, 24, color, width)
