class_name BalloonEnemy extends Enemy

@export var gravity: float = 50
@export var drift_speed: float = 30.0
@export var blow_force: float = 400.0
@export var blow_duration: float = 3.0
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var blowing_detector: Area2D = $BlowingDetector
@onready var wind: Wind = $Wind

func extra_ready_functions() -> void:
	animation_player = $AnimationPlayer
	state_machine.Initialize(self)
	
func _physics_process(_delta: float) -> void:
	if not is_committed():
		wind.face_player()
		face_player()
	move_and_slide()

func face_player() -> void:
	sprite.scale.x = sign(PlayerManager.player.global_position.x - global_position.x)
	
func is_committed() -> bool:
	return state_machine.curr_state is BalloonPreBlowState or state_machine.curr_state is BalloonBlowState
	
func apply_drift(_delta: float) -> void:
	velocity += Vector2(0, -gravity * _delta)
