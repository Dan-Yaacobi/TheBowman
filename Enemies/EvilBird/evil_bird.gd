class_name EvilBird extends Enemy

func extra_ready_functions() -> void:
	animation_player = $Sprite2D/AnimationPlayer
	state_machine.Initialize(self)
	
func _physics_process(_delta: float) -> void:
	move_and_slide()

func face_the_player() -> void:
	sprite.flip_h = PlayerManager.player.global_position.x > global_position.x
