class_name FlyingApple extends Enemy

@onready var wings: Sprite2D = $Sprite2D/Wings
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine

var wings_animation: AnimationPlayer

func extra_ready_functions() -> void:
	scale = Vector2(0.75,0.75)
	sprite.texture = stats.skin
	hurt_box.knockback_power = stats.knockback
	hurt_box.successful_hit.connect(knockback)
	wings_animation  = $Sprite2D/Wings/WingsAnimation
	animation_player = $Sprite2D/AnimationPlayer
	damaged_animation_player = $Sprite2D/DamagedAnimation
	if wings_animation != null:
		wings_animation.play("Fly")
	update_animation("Move")
	for ability in stats.initial_ability:
		ability.activate_ability(self)
	state_machine.Initialize(self)
	
func shoot() -> void:
	if stats.bullet != null:
		var new_bullet: EnemyBullet = stats.bullet.instantiate()
		new_bullet.direction = calculate_direction_to_player()
		new_bullet.global_position = global_position
		new_bullet.data.knockback = stats.knockback
		new_bullet.data.knockback = stats.knockback
		get_parent().add_child(new_bullet)
func _physics_process(_delta: float) -> void:
	move_and_slide()
