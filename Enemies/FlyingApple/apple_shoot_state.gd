class_name AppleShootState extends EnemyState

@onready var shoot_timer: Timer = $ShootTimer
@onready var seek: AppleSeekState = $"../Seek"

#what happens when we initialize this state
func init() -> void:
	shoot_timer.timeout.connect(done_shooting)

#what happens when the player enters this state
func Enter() -> void:
	enemy.velocity = Vector2.ZERO
	shoot()
	shoot_timer.start()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	shoot_timer.stop()
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
func done_shooting() -> void:
	state_machine.ChangeState(seek)

func shoot() -> void:
	if enemy.stats.bullet != null:
		var new_bullet: EnemyBullet = enemy.stats.bullet.instantiate()
		new_bullet.direction = enemy.calculate_direction_to_player()
		new_bullet.global_position = enemy.global_position
		new_bullet.data.knockback = enemy.stats.knockback
		new_bullet.data.knockback = enemy.stats.knockback
		enemy.get_parent().add_child(new_bullet)
