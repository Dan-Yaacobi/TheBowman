class_name AppleShootState extends EnemyState

@onready var shoot_timer: Timer = $ShootTimer
@onready var seek: AppleSeekState = $"../Seek"
@export var exit_margin: float = 20.0
@export var squeeze_amount: float = 0.2
@export var squeeze_time: float = 0.1
@export var release_time: float = 0.2

var direction: Vector2
var anim_tween: Tween
var base_scale: Vector2

#what happens when we initialize this state
func init() -> void:
	if !enemy.stats.pure_ranged_mode:
		shoot_timer.timeout.connect(done_shooting)
	else:
		shoot_timer.timeout.connect(_shoot)
		shoot_timer.wait_time = enemy.stats.shot_cooldown
		
#what happens when the player enters this state
func Enter() -> void:
	_shoot()
	if enemy.stats.pure_ranged_mode:
		enemy.velocity = Vector2.ZERO
	shoot_timer.start()
	
#what happens when the player exits this state
func Exit() -> void:
	shoot_timer.stop()
	_reset_scale()
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	enemy.knockback_velocity = enemy.knockback_velocity.lerp(Vector2.ZERO, enemy.stats.knockback_decay * _delta * 60)
	direction = enemy.calculate_direction_to_player()
	if enemy.knockback_velocity.length() > enemy.stats.knockback_threshold:
		enemy.velocity = enemy.knockback_velocity
	if enemy.calculate_distance_to_player() >= enemy.stats.ranged_trigger_distance + exit_margin:
		done_shooting()
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
func done_shooting() -> void:
	state_machine.ChangeState(seek)


func _shoot() -> void:
	enemy.shoot()
	_play_squeeze()


func _play_squeeze() -> void:
	if not enemy.can_process():
		return
	if anim_tween and anim_tween.is_running():
		anim_tween.kill()
	else:
		base_scale = enemy.scale
	var squeezed: Vector2 = base_scale * Vector2(1.0 + squeeze_amount, 1.0 - squeeze_amount)
	anim_tween = enemy.create_tween()
	anim_tween.tween_property(enemy, "scale", squeezed, squeeze_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(enemy, "scale", base_scale, release_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _reset_scale() -> void:
	if anim_tween and anim_tween.is_running():
		anim_tween.kill()
		enemy.scale = base_scale
