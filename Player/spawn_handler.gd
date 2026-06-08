class_name SpawnHandler extends Node2D
@onready var top_area: Area2D = $TopArea
@onready var left_area: Area2D = $LeftArea
@onready var bottom_area: Area2D = $BottomArea
@onready var right_area: Area2D = $RightArea
var all: Array[CollisionShape2D]
var top: CollisionShape2D
var left: CollisionShape2D
var bottom: CollisionShape2D
var right: CollisionShape2D

func _ready() -> void:
	top = top_area.get_child(0)
	left = left_area.get_child(0)
	bottom = bottom_area.get_child(0)
	right = right_area.get_child(0)
	all.append(top)
	all.append(left)
	all.append(bottom)
	all.append(right)

func _spawn_at(enemy_factory: Callable, shape: CollisionShape2D) -> Enemy:
	var enemy_node: Enemy = enemy_factory.call()
	if enemy_node == null:
		return null
	var boundary: Rect2 = shape.shape.get_rect()
	var local_pos: Vector2 = Vector2(
		randf_range(boundary.position.x, boundary.end.x),
		randf_range(boundary.position.y, boundary.end.y)
	)
	enemy_node.global_position = shape.global_position + local_pos
	return enemy_node

func spawn_from_top(enemy_factory: Callable) -> Enemy:
	return _spawn_at(enemy_factory, top)

func spawn_from_left(enemy_factory: Callable) -> Enemy:
	return _spawn_at(enemy_factory, left)

func spawn_from_bottom(enemy_factory: Callable) -> Enemy:
	return _spawn_at(enemy_factory, bottom)

func spawn_from_right(enemy_factory: Callable) -> Enemy:
	return _spawn_at(enemy_factory, right)

func spawn_from_any(enemy_factory: Callable) -> Enemy:
	return _spawn_at(enemy_factory, all.pick_random())

func spawn_grounded_from_player(enemy_factory: Callable, owner_node: GameWorld) -> void:
	var enemy_node: Enemy = enemy_factory.call()
	enemy_node.global_position = Vector2(PlayerManager.player.global_position.x, PlayerManager.player.global_position.y - 500)
	owner_node.add_enemy(enemy_node)
