class_name Bounds extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var colliding: bool = false

func _on_area_entered(area: Area2D) -> void:
	if area is Bounds:
		area.colliding = true

func get_boundaries() -> Rect2:
	var rect_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rect_shape == null:
		return Rect2(global_position, Vector2.ZERO)

	var ext: Vector2 = rect_shape.size * 0.5

	# rectangle corners in local space
	var p0: Vector2 = collision_shape.to_global(Vector2(-ext.x, -ext.y))
	var p1: Vector2 = collision_shape.to_global(Vector2( ext.x, -ext.y))
	var p2: Vector2 = collision_shape.to_global(Vector2( ext.x,  ext.y))
	var p3: Vector2 = collision_shape.to_global(Vector2(-ext.x,  ext.y))

	var min_x: float = min(p0.x, p1.x, p2.x, p3.x)
	var max_x: float = max(p0.x, p1.x, p2.x, p3.x)
	var min_y: float = min(p0.y, p1.y, p2.y, p3.y)
	var max_y: float = max(p0.y, p1.y, p2.y, p3.y)

	return Rect2(
		Vector2(min_x, min_y),
		Vector2(max_x - min_x, max_y - min_y)
	)

func intersects_with(other: Bounds) -> bool:
	return get_boundaries().intersects(other.get_boundaries(), true)
