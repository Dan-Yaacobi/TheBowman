class_name PortalPointer extends CanvasLayer
## Once the rift's exit portal has been seen, an arrow sticks to the screen edge pointing
## at it whenever it's off screen. Owned by the portal, so it goes away with it.

const EDGE_MARGIN: float = 40.0
const ARROW_SIZE: float = 22.0
const OUTLINE: Color = Color(0.08, 0.05, 0.06)

var portal: Node2D
var color: Color = Color(0.75, 0.5, 1.0)

var _marker: Control
var _time: float = 0.0
var _fade: float = 0.0

func _ready() -> void:
	layer = 5
	_marker = Control.new()
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_marker.draw.connect(_on_marker_draw)
	add_child(_marker)

func _process(delta: float) -> void:
	_time += delta
	var off_screen: bool = is_instance_valid(portal) and portal.is_visible_in_tree() \
		and not _in_event() and not _portal_on_screen()
	_fade = move_toward(_fade, 1.0 if off_screen else 0.0, delta * 5.0)
	_marker.queue_redraw()

## Events live far away in the same world, so the pointer would aim across the map.
func _in_event() -> bool:
	var node: Node = portal.get_parent()
	while node != null and not node is GameWorld:
		node = node.get_parent()
	return node != null and (node as GameWorld).current_event != null

func _portal_screen_position() -> Vector2:
	return portal.get_global_transform_with_canvas().origin

func _portal_on_screen() -> bool:
	return portal.get_viewport().get_visible_rect().grow(-8.0).has_point(_portal_screen_position())

func _on_marker_draw() -> void:
	if _fade <= 0.0 or not is_instance_valid(portal):
		return
	var rect: Rect2 = _marker.get_viewport_rect()
	var center: Vector2 = rect.get_center()
	var to_portal: Vector2 = _portal_screen_position() - center
	if to_portal == Vector2.ZERO:
		return
	var direction: Vector2 = to_portal.normalized()
	# Push the arrow out from the center until it meets the margin rectangle.
	var half: Vector2 = rect.size / 2.0 - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	var scale_x: float = half.x / absf(direction.x) if not is_zero_approx(direction.x) else INF
	var scale_y: float = half.y / absf(direction.y) if not is_zero_approx(direction.y) else INF
	var bob: float = sin(_time * 6.0) * 3.0
	var tip: Vector2 = center + direction * (minf(scale_x, scale_y) + bob)
	var side: Vector2 = direction.orthogonal()
	var size: float = ARROW_SIZE * (1.0 + 0.08 * sin(_time * 6.0))
	var arrow: PackedVector2Array = PackedVector2Array([
		tip,
		tip - direction * size * 1.4 + side * size,
		tip - direction * size * 0.8,
		tip - direction * size * 1.4 - side * size,
	])
	var glow_alpha: float = (0.25 + 0.15 * sin(_time * 4.0)) * _fade
	_marker.draw_circle(tip - direction * size * 0.9, size * 1.5, Color(color, glow_alpha))
	_marker.draw_colored_polygon(arrow, Color(color.lightened(0.15), _fade))
	var outline: PackedVector2Array = arrow.duplicate()
	outline.append(arrow[0])
	_marker.draw_polyline(outline, Color(OUTLINE, _fade), 3.0)
