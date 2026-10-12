class_name SpawnArea extends Area2D

@export var id: StringName = &"meteor"

@onready var shape_node: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Only used as a region; no detection needed
	monitoring = false
	monitorable = false

func random_point() -> Vector2:
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect == null:
		return global_position
	var half: Vector2 = rect.size * 0.5
	var local: Vector2 = Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y))
	return shape_node.global_transform * local
