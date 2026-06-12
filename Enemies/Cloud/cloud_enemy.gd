class_name CloudEnemy extends Enemy

func extra_ready_functions() -> void:
	animation_player = $Sprite2D/AnimationPlayer
	damaged_animation_player = $Sprite2D/DamagedAnimationPlayer
	state_machine.Initialize(self)
	
func _physics_process(_delta: float) -> void:
	move_and_slide()
