class_name FlyingRedAppleBoss extends FlyingApple

@onready var ground_detector: Area2D = $GroundDetector
@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var shoot_timer: Timer = $ShootTimer


func extra_ready_functions() -> void:
	scale *= 3
	enemy_state_machine.Initialize(self)
	
	debuff_handler.set_enemy(self)
	wings_animation  = $Sprite2D/Wings/WingsAnimation
	animation_player = $Sprite2D/AnimationPlayer
	if wings_animation != null:
		wings_animation.play("Fly")
		
	var shooter_random = randi_range(1,100)
	if shooter_random <= stats.shooter_chance:
		stats.shooter = true
	shoot_height = randi_range(50,80)
	
	animation_player.play("Move")

	hurt_box.knockback = stats.knockback
	hurt_box.damage = stats.touch_damage
	hurt_box.successful_hit.connect(push_back)
	hit_box.set_enemy(self)
	sprite.texture = stats.skin
	for ability in stats.initial_ability:
		ability.activate_ability(self)
		
func _physics_process(delta: float) -> void:
	move_and_slide()
	pass

#func shoot() -> void:
	#if stats.bullet != null and not stunned_state:
		#var new_bullet: EnemyBullet = stats.bullet.instantiate()
#
		#new_bullet.scale *= 2
		#if stats.shoot_speed != 0:
			#shoot_timer.wait_time = min(new_bullet.data.fire_cooldown,stats.shoot_speed)
		#else:
			#shoot_timer.wait_time = new_bullet.data.fire_cooldown
		#new_bullet.direction = calculate_direction_to_player()
		#new_bullet.global_position = global_position
		#new_bullet.data.knockback = stats.knockback
		#new_bullet.data.move_speed = stats.move_speed * 3
		#get_parent().add_child(new_bullet)
