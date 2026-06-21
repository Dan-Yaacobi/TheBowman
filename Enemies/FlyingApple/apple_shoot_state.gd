class_name AppleShootState extends EnemyState

@onready var shoot_timer: Timer = $ShootTimer
@onready var seek: AppleSeekState = $"../Seek"
var direction: Vector2

#what happens when we initialize this state
func init() -> void:
	shoot_timer.timeout.connect(done_shooting)

#what happens when the player enters this state
func Enter() -> void:
	#enemy.velocity = Vector2.ZERO
	enemy.shoot()
	shoot_timer.start()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	shoot_timer.stop()
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	enemy.knockback_velocity = enemy.knockback_velocity.lerp(Vector2.ZERO, enemy.knockback_decay * _delta * 60)
	direction = enemy.calculate_direction_to_player()
	if enemy.knockback_velocity.length() > enemy.knockback_threshold:
		enemy.velocity = enemy.knockback_velocity
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
func done_shooting() -> void:
	state_machine.ChangeState(seek)
