class_name EvilBird extends Enemy

#@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var hit_box: Area2D = $HitBox
@onready var hurt_box: Area2D = $HurtBox
@onready var sprite: Sprite2D = $Sprite2D

var shooting_state: bool = false

var left_end_pos: int
var right_end_pos: int
var fly_direction: int = -1
var shoot_speed: float = 0

func _ready() -> void:
	animation_player = $Sprite2D/AnimationPlayer
	animation_player.play("Move")
	hit_box.area_entered.connect(hit)
	hurt_box.body_entered.connect(player_hit)
	sprite.texture = stats.skin
	for ability in stats.initial_ability:
		ability.activate_ability(self)
	left_end_pos = -randi_range(30,60)
	right_end_pos = randi_range(30,60)
	#shoot_speed = stats.shoot_speed

	
func _physics_process(delta: float) -> void:

	if poisoned_state and poisoned_timer != null:
		if poisoned_timer.is_stopped():
			poisoned_timer.start()
	
	if stunned_state and stunned_timer != null:
		velocity = Vector2.ZERO
		if stunned_timer.is_stopped():
			stunned_timer.start()

	if not shooting_state:
		if player.global_position.x > global_position.x:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
		velocity += calculate_direction_to_player() * stats.move_speed * delta
		shooting_state = check_if_reached_height()
	else:
		fly_and_shoot(delta)

	activate_debuffs()
	move_and_slide()

func check_if_reached_height() -> bool:
	if abs(global_position.y) < abs(player.global_position.y + randi_range(50,80)):
		sprite.flip_h = false
		return true
	return false

func fly_and_shoot(delta) -> void:
	velocity = Vector2(fly_direction * stats.move_speed / 2,0)
	
	shoot_speed -= delta
	if shoot_speed <= 0:
		shoot()
		
	if fly_direction == 1:
		if global_position.x > right_end_pos:
			fly_direction *= -1
			sprite.flip_h = not sprite.flip_h
	elif fly_direction == -1:
		if global_position.x < left_end_pos:
			fly_direction *= -1
			sprite.flip_h = not sprite.flip_h
	
	pass

func shoot() -> void:
	shoot_speed = randf_range(stats.shoot_speed/2, stats.shoot_speed)
	if stats.bullet != null and not stunned_state:
		var new_bullet: EnemyBullet = stats.bullet.instantiate()
		new_bullet.global_position = global_position
		new_bullet.scale *= 0.7
		new_bullet.data.damage = self.stats.touch_damage
		new_bullet.data.knockback = self.stats.knockback / 2
		get_parent().add_child(new_bullet)
	pass
