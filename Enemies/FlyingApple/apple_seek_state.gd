class_name AppleSeekState extends EnemyState

@onready var decide: AppleDecideState = $"../Decide"
@onready var shoot: AppleShootState = $"../Shoot"

var direction: Vector2
var distance_to_strike: int = 30
var succesfull_hit: bool
#what happens when we initialize this state

func init() -> void:
	enemy.hurt_box.successful_hit.connect(hit_player)
	pass

#what happens when the player enters this state
func Enter() -> void:
	succesfull_hit = false
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	var modifier: int = 1
	if enemy.calculate_distance_to_player() <= distance_to_strike:
		modifier = 2
	enemy.knockback_velocity = enemy.knockback_velocity.lerp(Vector2.ZERO, enemy.knockback_decay * _delta * 60)
	direction = enemy.calculate_direction_to_player()
	if enemy.knockback_velocity.length() > enemy.knockback_threshold:
		enemy.velocity = enemy.knockback_velocity
		return null
	if succesfull_hit:
		return shoot
	else:
		enemy.velocity = direction * enemy.stats.move_speed.value() * modifier
	return null

func hit_player(_var) -> void:
	succesfull_hit = true
	pass
	
