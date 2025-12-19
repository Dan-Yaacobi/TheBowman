class_name EnemySpawner extends Node2D

@onready var spawn_area: CollisionShape2D = $SpawnArea/CollisionShape2D
@onready var spawn_timer: Timer = $SpawnTimer

@export var data: EnemySpawnerData
@export var active: bool = false
@export var spawn_time: float = 2.0
@export var difficulty: int = 0

signal summoned(enemy: Enemy)

const POWER_ORB = preload("uid://ccp2hrnf3s4hu")

func _ready() -> void:
	spawn_timer.timeout.connect(summon)
	spawn_timer.wait_time = spawn_time - difficulty * 0.2
	
func summon() -> void:
	var new_enemy: Enemy = data.get_apple(difficulty)
	if data.total > 0:
		new_enemy.global_position = get_spawn_position()
		summoned.emit(new_enemy)
		data.total -= 1
		
	if data.total <= 0:
		active = false
		spawn_timer.stop()
		new_enemy.died.connect(summon_orb)
		
func _on_player_detector_body_entered(body: Node2D) -> void:
	if body is Player and active:
		summon()
		spawn_timer.start()
		
func get_spawn_position() -> Vector2:
	
	var cs: CollisionShape2D = $SpawnArea/CollisionShape2D
	var rect: RectangleShape2D = cs.shape as RectangleShape2D
	if rect == null:
		return cs.global_position

	var ext: Vector2 = rect.size * 0.5
	var local_point: Vector2 = Vector2(
		randf_range(-ext.x, ext.x),
		randf_range(-ext.y, ext.y)
	)

	return cs.to_global(local_point)

func summon_orb(_enemy: Enemy) -> void:
	call_deferred("add_child", POWER_ORB.instantiate())
