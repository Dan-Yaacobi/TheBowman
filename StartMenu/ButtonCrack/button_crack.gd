class_name ButtonCrack extends Node2D
## Cracks that splinter out from where an arrow hit a menu button. Random each
## time, snapped to a pixel grid, spread out in a few frames. Lives on the button
## until the screen changes.

const GROUP: StringName = &"button_crack"

@export var radius: float = 26.0
@export var branch_count: Vector2i = Vector2i(4, 6)
@export var spread_time: float = 0.09
@export var pixel_size: float = 2.0
@export var crack_color: Color = Color(0.08, 0.05, 0.04, 0.85)
@export var edge_color: Color = Color(1.0, 0.95, 0.85, 0.35)

## Each crack is a polyline from the impact point outward.
var _lines: Array[PackedVector2Array] = []
var _progress: float = 0.0

func _ready() -> void:
	add_to_group(GROUP)
	_build()
	var tween: Tween = create_tween()
	tween.tween_property(self, "_progress", 1.0, spread_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _process(_delta: float) -> void:
	if _progress < 1.0:
		queue_redraw()

func _build() -> void:
	var count: int = randi_range(branch_count.x, branch_count.y)
	var start_angle: float = randf() * TAU
	for i: int in count:
		var angle: float = start_angle + TAU * i / count + randf_range(-0.35, 0.35)
		var length: float = radius * randf_range(0.55, 1.0)
		var line: PackedVector2Array = _jagged(Vector2.ZERO, angle, length, 4)
		_lines.append(line)
		# A short side branch off the middle of some cracks.
		if randf() < 0.6 and line.size() > 2:
			var fork: float = angle + randf_range(0.5, 0.9) * (1.0 if randf() < 0.5 else -1.0)
			_lines.append(_jagged(line[line.size() / 2], fork, length * 0.4, 2))

func _jagged(from: Vector2, angle: float, length: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = [_snap(from)]
	var point: Vector2 = from
	for s: int in segments:
		var heading: float = angle + randf_range(-0.45, 0.45)
		point += Vector2.RIGHT.rotated(heading) * (length / segments)
		points.append(_snap(point))
	return points

func _snap(point: Vector2) -> Vector2:
	return (point / pixel_size).round() * pixel_size

func _draw() -> void:
	for line: PackedVector2Array in _lines:
		var shown: PackedVector2Array = _partial(line, _progress)
		if shown.size() < 2:
			continue
		# A pale lip on one side reads as a chipped edge.
		var lip: PackedVector2Array = shown.duplicate()
		for i: int in lip.size():
			lip[i] += Vector2(pixel_size, pixel_size) * 0.5
		draw_polyline(lip, edge_color, pixel_size * 0.5)
		draw_polyline(shown, crack_color, pixel_size)

## The first `t` (0..1) of a polyline, by point count.
func _partial(line: PackedVector2Array, t: float) -> PackedVector2Array:
	var exact: float = t * (line.size() - 1)
	var whole: int = floori(exact)
	var result: PackedVector2Array = line.slice(0, whole + 1)
	if whole < line.size() - 1:
		result.append(line[whole].lerp(line[whole + 1], exact - whole))
	return result
