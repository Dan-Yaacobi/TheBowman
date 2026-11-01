class_name FlyingRedAppleBoss extends Boss

@onready var ground_detector: Area2D = $GroundDetector
@onready var shoot_timer: Timer = $ShootTimer

@export var flying_apple_entry: EnemyEntry

var player: Player
var half_hp_activation: bool = false

func extra_ready_functions() -> void:
	half_hp_activation = false
	animation_player = $Sprite2D/AnimationPlayer
	state_machine.Initialize(self)
	animation_player.play("Move")
	player = PlayerManager.player

func _on_fight_began() -> void:
	for ability in stats.initial_ability:
		ability.activate_ability(self)

func _physics_process(_delta: float) -> void:
	face_the_player()
	move_and_slide()
