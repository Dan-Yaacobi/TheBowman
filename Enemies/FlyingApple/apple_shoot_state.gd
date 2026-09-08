class_name AppleShootState extends EnemyState

@onready var shoot_timer: Timer = $ShootTimer
@onready var seek: AppleSeekState = $"../Seek"
var direction: Vector2

#what happens when we initialize this state
func init() -> void:
	if !enemy.stats.pure_ranged_mode:
		shoot_timer.timeout.connect(done_shooting)
	else:
		shoot_timer.timeout.connect(enemy.shoot)
		shoot_timer.wait_time = enemy.stats.shot_cooldown
		
#what happens when the player enters this state
func Enter() -> void:
	enemy.shoot()
	if enemy.stats.pure_ranged_mode:
		enemy.velocity = Vector2.ZERO
	shoot_timer.start()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	shoot_timer.stop()
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	enemy.knockback_velocity = enemy.knockback_velocity.lerp(Vector2.ZERO, enemy.stats.knockback_decay * _delta * 60)
	direction = enemy.calculate_direction_to_player()
	if enemy.knockback_velocity.length() > enemy.stats.knockback_threshold:
		enemy.velocity = enemy.knockback_velocity
	if enemy.calculate_distance_to_player() >= enemy.stats.ranged_trigger_distance:
		done_shooting()
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
func done_shooting() -> void:
	state_machine.ChangeState(seek)
