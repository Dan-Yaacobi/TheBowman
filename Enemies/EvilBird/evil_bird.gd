class_name EvilBird extends Enemy

@onready var fly_to_roost_state: BirdFlyToRoostState = $EnemyStateMachine/FlyToRoost

func extra_ready_functions() -> void:
	animation_player = $Sprite2D/AnimationPlayer
	state_machine.Initialize(self)
	
func _physics_process(_delta: float) -> void:
	move_and_slide()

func fly_to_roost(_position: Vector2) -> void:
	fly_to_roost_state.roost_target = _position
	state_machine.ChangeState(fly_to_roost_state)
	pass

func bullet_set_up() -> Node2D:
	if stats.bullet != null:
		var new_bullet: EnemyBullet = stats.bullet.instantiate()
		new_bullet.global_position = global_position
		new_bullet.scale *= 0.7
		new_bullet.data.damage = stats.touch_damage
		new_bullet.data.knockback = stats.knockback
		new_bullet.set_texture(stats.bullet_sprite)
		return new_bullet
	return null
