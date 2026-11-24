@tool
class_name ConnectorMarker extends Marker2D
## A snap point on a LevelPiece. When a piece is dropped in the editor and one of its
## connectors lands within snap radius of another piece's connector, the piece moves so
## the two connectors sit on the same point.
## In the editor: green circle = snap radius. Hidden in game.

const GROUP: StringName = &"level_connector"
const RADIUS_COLOR: Color = Color(0.3, 1.0, 0.5, 0.8)
const POINT_COLOR: Color = Color(0.3, 1.0, 0.5, 1.0)
const CIRCLE_WIDTH: float = 1.0
const POINT_RADIUS: float = 1.5

## Connectors snap when they are this close. Two connectors snap if either one's radius reaches.
@export var snap_radius: float = 16.0:
	set(value):
		snap_radius = maxf(value, 0.0)
		queue_redraw()


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, POINT_RADIUS, POINT_COLOR)
	if snap_radius > 0.0:
		draw_arc(Vector2.ZERO, snap_radius, 0.0, TAU, 32, RADIUS_COLOR, CIRCLE_WIDTH)
