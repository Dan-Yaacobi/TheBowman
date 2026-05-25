class_name FlyingApple extends Enemy

@onready var wings: Sprite2D = $Sprite2D/Wings

@export var tree_spawn: bool = false

var wings_animation: AnimationPlayer
var shoot_height: int = 80
var shoot_cooldown: float = 0
var start_moving: bool = false

func extra_ready_functions() -> void:
	scale = Vector2(0.75,0.75)
	sprite.texture = stats.skin
	if tree_spawn:
		wings.visible = false
		start_moving = false
		hit_box.monitorable = false
		hurt_box.monitoring = false
		hurt_box.monitorable = false
	else:
		initialize()


func initialize() -> void:
	hit_box.monitorable = true
	hurt_box.monitoring = true
	hurt_box.monitorable = true
	hurt_box.knockback = stats.knockback
	hurt_box.damage = stats.touch_damage
	hurt_box.successful_hit.connect(push_back)
	wings_animation  = $Sprite2D/Wings/WingsAnimation
	animation_player = $Sprite2D/AnimationPlayer
	damaged_animation_player = $Sprite2D/DamagedAnimation
	if wings_animation != null:
		wings_animation.play("Fly")
		
	var shooter_random = randi_range(1,100)
	if shooter_random <= stats.shooter_chance:
		stats.shooter = true
	shoot_height = randi_range(50,80)

	for ability in stats.initial_ability:
		ability.activate_ability(self)
	start_moving = true
	update_animation("Move")
	hit_box.monitorable = true
	wings.visible = true
	start_moving = true
	velocity = Vector2.ZERO
	
func spawn_from_tree() -> void:
	velocity.y = 15
	await get_tree().create_timer(1.0).timeout
	initialize()

func _physics_process(delta: float) -> void:
	if start_moving:
		direction = calculate_direction_to_player()
		
		if pushed_back:
			velocity = pushback_dir * pushback_power
			pushback_power -= delta * stats.knockback_resistance
			if pushback_power <= 0:
				pushed_back = false
				
		
		elif stats.shooter:
			shooting(delta)
		
		else:
			velocity = direction * stats.move_speed.value()
	move_and_slide()
	
func shooting(delta: float) -> void:
	if abs(global_position.y - PlayerManager.player.global_position.y) > shoot_height:
		velocity  += calculate_direction_to_player() * stats.move_speed.value() * delta
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
		new_bullet.position = position
		new_bullet.data.knockback = stats.knockback
		new_bullet.data.knockback = stats.knockback
		get_parent().add_child(new_bullet)
	
