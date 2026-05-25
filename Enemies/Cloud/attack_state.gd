class_name CloudAttackState extends EnemyState

@onready var attack_timer: Timer = $AttackTimer
@onready var wander: CloudWanderState = $"../Wander"
@onready var sprite: Sprite2D = $"../../Sprite2D"
@onready var lightning: Lightning = $Lightning

#what happens when we initialize this state
func init() -> void:
	attack_timer.timeout.connect(summon_rain_drop)
	lightning.finished.connect(done_attacking)
	pass

#what happens when the player enters this state
func Enter() -> void:
	attack_timer.stop()
	sprite.frame = 5
	#attack_timer.stop()
	enemy.velocity = Vector2.ZERO
	var target_pos = PlayerManager.player.global_position + Vector2(0,16)
	var tween := create_tween()
	tween.tween_property(sprite.material, "shader_parameter/charge", 1.0,1.0)
	await tween.finished
	
	cast_lightning(target_pos)
	
	
#what happens when the player exits this state
func Exit() -> void:
	var tween := create_tween()
	tween.tween_property(sprite.material, "shader_parameter/charge", 0.0, 0.3)
	attack_timer.start()

	#lightning.clear_points()
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	#if total_raindrops <= 0:
		#return null
		#return wander
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null

func done_attacking() -> void:
	lightning.done()
	state_machine.ChangeState(wander)
	
func cast_lightning(_target: Vector2) -> void:
	lightning.generate_lightning_global(enemy.global_position, _target)
	
func summon_rain_drop() -> void:
	var new_raindrop: RainDrop = enemy.stats.bullet.instantiate()
	new_raindrop.global_position = enemy.global_position + Vector2(randi_range(-10,10),10)
	enemy.get_parent().add_child(new_raindrop)
	attack_timer.wait_time = randf_range(0.5,1.5)
