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
## ISLAND = ground enemies placed on a free object spot of a nearby island
enum Zone { ANY, TOP, LEFT, BOTTOM, RIGHT, ISLAND }

@export_group("Island Spawns")
## Islands closer than this to the player are skipped, so the enemy isn't spawned on top of them
@export var island_min_distance: float = 160.0
## Islands further than this from the player are skipped
@export var island_max_distance: float = 500.0

func _ready() -> void:
	top = top_area.get_child(0)
	left = left_area.get_child(0)
	bottom = bottom_area.get_child(0)
	right = right_area.get_child(0)
	all.append(top)
	all.append(left)
	all.append(bottom)
	all.append(right)


func spawn_from_zone(enemy_factory: Callable, zone: Zone) -> Enemy:
	match zone:
		Zone.TOP: return spawn_from_top(enemy_factory)
		Zone.LEFT: return spawn_from_left(enemy_factory)
		Zone.BOTTOM: return spawn_from_bottom(enemy_factory)
		Zone.RIGHT: return spawn_from_right(enemy_factory)
		Zone.ISLAND: return spawn_on_island(enemy_factory)
		_: return spawn_from_any(enemy_factory)
		
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

## Returns null when no island in range has a free object spot.
func spawn_on_island(enemy_factory: Callable) -> Enemy:
	var island: Island = _pick_spawn_island()
	if island == null:
		return null
	var enemy_node: Enemy = enemy_factory.call()
	if enemy_node == null:
		return null
	enemy_node.global_position = island.claim_object_spot()
	return enemy_node

func _pick_spawn_island() -> Island:
	var player_pos: Vector2 = PlayerManager.player.global_position
	var candidates: Array[Island] = []
	for node: Node in get_tree().get_nodes_in_group(Island.GROUP):
		var island: Island = node as Island
		if island == null or not island.is_solid() or not island.has_free_object_spot():
			continue
		var distance: float = island.global_position.distance_to(player_pos)
		if distance >= island_min_distance and distance <= island_max_distance:
			candidates.append(island)
	if candidates.is_empty():
		return null
	return candidates.pick_random()

func spawn_grounded_from_player(enemy_factory: Callable, owner_node: GameWorld) -> void:
	var enemy_node: Enemy = enemy_factory.call()
	enemy_node.global_position = Vector2(PlayerManager.player.global_position.x, PlayerManager.player.global_position.y - 500)
	owner_node.add_enemy(enemy_node)
