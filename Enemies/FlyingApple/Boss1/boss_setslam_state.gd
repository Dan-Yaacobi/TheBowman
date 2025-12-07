class_name BossSetSlamState extends EnemyState

@onready var slam: BossSlamState = $"../Slam"

var target_slam_position: Vector2
var slam_height: int
var set_slam_direction: Vector2
var offset: int = 10
func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.velocity = Vector2.ZERO
	slam_height = randi_range(60,80)
	target_slam_position = Vector2(enemy.player.global_position.x , enemy.player.global_position.y - slam_height)
	set_slam_direction = (target_slam_position - enemy.global_position).normalized()
	enemy.velocity = set_slam_direction*enemy.stats.move_speed * 3
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	if enemy.global_position.x > target_slam_position.x - offset and enemy.global_position.x < target_slam_position.x + offset:
		if enemy.global_position.y < target_slam_position.y: 
			return slam
	return null
	
