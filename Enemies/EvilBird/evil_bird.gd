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
	
