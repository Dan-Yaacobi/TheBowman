@tool
class_name TargetRoute extends Node2D

@export var line_color: Color = Color(1.0, 0.4, 0.2, 0.8)

@onready var start_marker: Marker2D = $Start
@onready var end_marker: Marker2D = $End

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var start: Marker2D = get_node_or_null("Start")
	var end: Marker2D = get_node_or_null("End")
	if start and end:
		draw_line(start.position, end.position, line_color, 2.0)

func get_start() -> Vector2:
	return start_marker.global_position

func get_end() -> Vector2:
	return end_marker.global_position
