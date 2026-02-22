class_name CloudSeekState extends EnemyState
@onready var attack: CloudAttackState = $"../Attack"

var target_rain_position: Vector2
var rain_height: int
var set_rain_direction: Vector2
var offset: int = 15

func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.velocity = Vector2.ZERO
	rain_height = randi_range(60,80)
	target_rain_position = Vector2(PlayerManager.player.global_position.x , PlayerManager.player.global_position.y - rain_height)
	set_rain_direction = (target_rain_position - enemy.global_position).normalized()
	enemy.velocity = set_rain_direction*enemy.stats.move_speed.value() * 5
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	
	if abs(enemy.global_position.x - target_rain_position.x) <= offset and enemy.global_position.y < target_rain_position.y:
		return attack
	return null
	
