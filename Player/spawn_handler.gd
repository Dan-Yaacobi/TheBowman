class_name SpawnHandler extends Node2D

signal grounded_positions_found(positions: Array[Vector2])

@onready var top_area: Area2D = $TopArea
@onready var left_area: Area2D = $LeftArea
@onready var bottom_area: Area2D = $BottomArea
@onready var right_area: Area2D = $RightArea

var all: Array[CollisionShape2D]
var top: CollisionShape2D
var left: CollisionShape2D
var bottom: CollisionShape2D
var right: CollisionShape2D

var _searching_ground: bool = false
var _ground_search_x: float
var _ground_search_end_x: float
var _ground_search_y: float
var _ground_search_results: Array[Vector2]
var _ground_search_count: int
const SEARCH_STEP: float = 20.0

func _ready() -> void:
	top = top_area.get_child(0)
	left = left_area.get_child(0)
	bottom = bottom_area.get_child(0)
	right = right_area.get_child(0)
	
	all.append(top)
	all.append(left)
	all.append(bottom)
	all.append(right)
	
func _process(_delta: float) -> void:
	if not _searching_ground:
		return
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		Vector2(_ground_search_x, _ground_search_y),
		Vector2(_ground_search_x, _ground_search_y + 2000.0)
	)
	if space_state.intersect_ray(query):
		_ground_search_results.append(Vector2(_ground_search_x, _ground_search_y))
	
	_ground_search_x += SEARCH_STEP
	
	if _ground_search_x > _ground_search_end_x:
		_searching_ground = false
		_ground_search_results.shuffle()
		grounded_positions_found.emit(_ground_search_results.slice(0, min(_ground_search_count, _ground_search_results.size())))

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
	
func start_grounded_top_search(count: int) -> void:
	var boundary: Rect2 = top.shape.get_rect()
	_ground_search_x = top.global_position.x + boundary.position.x
	_ground_search_end_x = top.global_position.x + boundary.end.x
	_ground_search_y = top.global_position.y
	_ground_search_results = []
	_ground_search_count = count
	_searching_ground = true

## Will return as many valid positions it can find, could be less than requested and is up to the caller to handle that.
func spawn_grounded_from_top(enemy_factory: Callable, count: int, owner_node: GameWorld) -> void:
	grounded_positions_found.connect(func(positions: Array[Vector2]) -> void:
		for pos in positions:
			var enemy_node: Enemy = enemy_factory.call()
			enemy_node.global_position = pos
			owner_node.add_enemy(enemy_node)
	, CONNECT_ONE_SHOT)
	start_grounded_top_search(count)
