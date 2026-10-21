class_name FlyingApple extends Enemy

func extra_ready_functions() -> void:
	sprite.texture = stats.skin
	animation_player = $Sprite2D/AnimationPlayer
	for ability in stats.initial_ability:
		ability.activate_ability(self)
	state_machine.Initialize(self)
	
func _physics_process(_delta: float) -> void:
	face_the_player()
	move_and_slide()
