class_name TreeSpawner extends EnemySpawner
@onready var spawn_markers: Node2D = $SpawnMarkers

var apples: Array[FlyingApple] = []
var spawn_positions: Array[Vector2]

func extra_ready_functions() -> void:
	for child in spawn_markers.get_children():
		spawn_positions.append(child.position)
		spawn_positions.shuffle()
	EventBus.entered_rift.connect(set_apples)
	
func set_apples() -> void:
	for i in data.total:
		var new_enemy: FlyingApple = data.get_apple(difficulty)
		new_enemy.tree_spawn = true
		apples.append(new_enemy)
		new_enemy.global_position = get_spawn_position()
		new_enemy.died.connect(apple_died)
		#summoned.emit(new_enemy)
		add_child(new_enemy)
func summon() -> void:
	if not apples.is_empty():
		var apple = 	apples.pop_back()
		EventBus.enemy_summoned.emit(apple)
		apple.spawn_from_tree()
		
func get_spawn_position() -> Vector2:
	return spawn_positions.pop_front()

func apple_died(_enemy: FlyingApple) -> void:
	apples.erase(_enemy)
	if apples.size() == 0:
		active = false
		spawn_timer.stop()
		summon_orb(null)
