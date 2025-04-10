class_name Skeleton extends Companion

var companion_state_machine: CompanionStateMachine 
var sprite: Sprite2D
var ray_cast_left: RayCast2D
var ray_cast_right: RayCast2D

func _ready() -> void:
	area = $AttackArea
	ray_cast_left = $RayCastLeft
	ray_cast_right = $RayCastRight
	sprite = $Sprite2D
	animation_player = $Sprite2D/AnimationPlayer
	area.body_entered.connect(focus_enemy)
	area.body_exited.connect(unfocus_enemy)
	companion_state_machine = $CompanionStateMachine
	companion_state_machine.Initialize(self)
	data.move_speed = randi_range(800,1500)
	pass
	
func _physics_process(delta: float) -> void:
	move_and_slide()
