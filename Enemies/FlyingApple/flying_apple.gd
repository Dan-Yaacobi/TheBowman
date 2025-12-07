class_name FlyingApple extends Enemy

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: EnemyHitBox = $HitBox

var wings_animation: AnimationPlayer
var shoot_height: int = 80
var shoot_cooldown: float = 0

func extra_ready_functions() -> void:
	debuff_handler.set_enemy(self)
	wings_animation  = $Sprite2D/Wings/WingsAnimation
	animation_player = $Sprite2D/AnimationPlayer
	damaged_animation_player = $Sprite2D/DamagedAnimation
	if wings_animation != null:
		wings_animation.play("Fly")
		
	var shooter_random = randi_range(1,100)
	if shooter_random <= stats.shooter_chance:
		stats.shooter = true
	shoot_height = randi_range(50,80)
	
	update_animation("Move")

	hurt_box.knockback = stats.knockback
	hurt_box.damage = stats.touch_damage
	hurt_box.successful_hit.connect(push_back)
	hit_box.set_enemy(self)
	sprite.texture = stats.skin
	for ability in stats.initial_ability:
		ability.activate_ability(self)

func _physics_process(delta: float) -> void:
	direction = calculate_direction_to_player()
	
	if pushed_back:
		velocity = pushback_dir * pushback_power
		pushback_power -= delta * stats.knockback_resistance
		if pushback_power <= 0:
			pushed_back = false
			
	elif stunned_state:
		velocity = Vector2.ZERO
	
	elif stats.shooter:
		shooting(delta)
	
	else:
		velocity = direction * stats.move_speed
	move_and_slide()
	
func shooting(delta: float) -> void:
	if abs(global_position.y - PlayerManager.player.global_position.y) > shoot_height:
		velocity  += calculate_direction_to_player() * stats.move_speed * delta
	else:
		velocity = Vector2.ZERO
		shoot_cooldown -= delta
		if shoot_cooldown <= 0:
			shoot()
	pass
	
func shoot() -> void:
	if stats.bullet != null:
		var new_bullet: EnemyBullet = stats.bullet.instantiate()

		shoot_cooldown = new_bullet.data.fire_cooldown
		new_bullet.direction = calculate_direction_to_player()
		new_bullet.global_position = global_position
		new_bullet.data.knockback = stats.knockback
		new_bullet.data.knockback = stats.knockback
		
		get_parent().add_child(new_bullet)
	
