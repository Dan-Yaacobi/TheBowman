class_name RamTelegraph extends Line2D
## The ram warning line: runs from an enemy along its charge path, fades in over the windup
## and flashes when the aim locks. Used by apple rams and snowflakes.

@export var aim_color: Color = Color(1.0, 0.3, 0.2, 0.55)
## Color the line flashes to when the aim locks.
@export var locked_color: Color = Color(1.0, 0.95, 0.85, 0.9)


func _init() -> void:
	top_level = true
	width = 1.0
	antialiased = false
	z_index = 1
	points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	visible = false


## progress: 0 at the start of the windup, 1 at the end.
func show_aim(origin: Vector2, direction: Vector2, length: float, progress: float, locked: bool) -> void:
	visible = true
	global_position = origin
	set_point_position(1, direction * length)
	if locked:
		default_color = locked_color
	else:
		var color: Color = aim_color
		color.a *= clampf(progress, 0.0, 1.0)
		default_color = color


func hide_aim() -> void:
	visible = false
