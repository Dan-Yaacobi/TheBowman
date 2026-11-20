class_name MenuScenery extends SubViewportContainer
## The title screen's living backdrop: a pixel-art world drawn at its own low
## resolution and scaled up crisp to fill the screen. Its layers drift with the
## mouse, and shoot() sends an arrow into it that hits whatever is under the
## cursor (nearest first), or flies past into the distance.

signal arrow_landed(target: MenuTarget)

@export var arrow_scene: PackedScene
## How far a fully near layer drifts with the mouse at the screen's edge, in art pixels.
@export var parallax_strength: Vector2 = Vector2(7.0, 2.5)
## The sun: where perspective converges and where missed arrows disappear to (art pixels).
@export var vanishing_point: Vector2 = Vector2(344.0, 229.0)
## Arrow landing scale at the horizon (x) and right in front of the viewer (y).
@export var arrow_scale_range: Vector2 = Vector2(0.35, 1.0)
## Arrows come from below the view, this far (min, max) to the side of its middle, in art pixels.
@export var launch_spread: Vector2 = Vector2(90.0, 230.0)

@onready var view: SubViewport = $View
@onready var shots: Node2D = %Shots
@onready var portal_island: MenuPortalIsland = %PortalIsland

## Zoom on top of the fit-to-screen scale, around `zoom_focus`.
var zoom: float = 1.0:
	set(value):
		zoom = value
		_apply_zoom()
## The point (view pixels) that stays put while zooming.
var zoom_focus: Vector2 = Vector2.ZERO

var _layers: Array[MenuLayer] = []
## Every target, in draw order: later ones are nearer the viewer.
var _targets: Array[MenuTarget] = []
var _parallax: Vector2 = Vector2.ZERO
var _base_scale: float = 1.0
var _base_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	size = Vector2(view.size)
	_collect(view)
	_fit()

func _process(delta: float) -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	var mouse: Vector2 = get_viewport().get_mouse_position() / screen_size - Vector2(0.5, 0.5)
	mouse = mouse.clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5))
	_parallax = _parallax.lerp(-mouse * 2.0 * parallax_strength, 1.0 - exp(-3.0 * delta))
	for layer: MenuLayer in _layers:
		layer.apply_parallax(_parallax)

## Converts a point on the screen into view pixels (the SubViewport's own resolution).
func screen_to_view(point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * point

## Where the rift portal is, in view pixels (for zooming into it).
func get_portal_point() -> Vector2:
	return portal_island.get_portal_center()

## Fires an arrow from the viewer at `screen_point`.
func shoot(screen_point: Vector2) -> void:
	var point: Vector2 = screen_to_view(screen_point)
	var hit: MenuTarget = null
	var passed: Array[MenuTarget] = []
	for i: int in range(_targets.size() - 1, -1, -1):
		var target: MenuTarget = _targets[i]
		if not target.covers(point):
			continue
		if target.stops_arrow:
			hit = target
			break
		passed.append(target)

	var arrow: MenuArrow = arrow_scene.instantiate()
	shots.add_child(arrow)
	# Arrows fly in art pixels (the Shots node's space), however finely the view is rendered.
	var view_size: Vector2 = Vector2(view.size)
	var side: float = -signf(point.x - view_size.x * 0.5)
	if is_zero_approx(side):
		side = 1.0 if randf() < 0.5 else -1.0
	var bottom_middle: Vector2 = shots.to_local(Vector2(view_size.x * 0.5, view_size.y))
	var from: Vector2 = bottom_middle + Vector2(side * randf_range(launch_spread.x, launch_spread.y), 90.0)
	var center: Vector2 = vanishing_point
	_puff_when_crossed(passed, point, arrow.flight_time)

	if hit == null:
		arrow.end_scale = lerpf(arrow_scale_range.x, arrow_scale_range.y, 0.6)
		arrow.fly_off(from, shots.to_local(point), center)
		arrow_landed.emit(null)
		return

	var local_point: Vector2 = hit.to_local(point)
	arrow.end_scale = lerpf(arrow_scale_range.x, arrow_scale_range.y, hit.get_depth())
	await arrow.fire(from, local_point, center, hit)
	if not is_instance_valid(arrow) or not arrow.is_inside_tree():
		return
	if not is_instance_valid(hit):
		arrow.vanish()
		return
	hit.react(arrow, local_point)
	arrow_landed.emit(hit)

func _puff_when_crossed(passed: Array[MenuTarget], point: Vector2, delay: float) -> void:
	if passed.is_empty():
		return
	await get_tree().create_timer(delay).timeout
	for target: MenuTarget in passed:
		if is_instance_valid(target):
			target.on_passed_through(target.to_local(point))

func _collect(node: Node) -> void:
	for child: Node in node.get_children():
		if child is MenuLayer:
			_layers.append(child)
		if child is MenuTarget:
			_targets.append(child)
		_collect(child)

func _fit() -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	var view_size: Vector2 = Vector2(view.size)
	_base_scale = maxf(screen_size.x / view_size.x, screen_size.y / view_size.y)
	_base_position = (screen_size - view_size * _base_scale) * 0.5
	zoom_focus = view_size * 0.5
	_apply_zoom()

func _apply_zoom() -> void:
	var focus_on_screen: Vector2 = _base_position + zoom_focus * _base_scale
	scale = Vector2.ONE * _base_scale * zoom
	position = focus_on_screen - zoom_focus * _base_scale * zoom
