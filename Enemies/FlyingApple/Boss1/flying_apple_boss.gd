class_name FlyingRedAppleBoss extends Boss

@onready var ground_detector: Area2D = $GroundDetector
@onready var shoot_timer: Timer = $ShootTimer
@onready var wings: Sprite2D = $Sprite2D/Wings

@export var flying_apple_entry: EnemyEntry

var wings_animation: AnimationPlayer

var player: Player
var half_hp_activation: bool = false

func extra_ready_functions() -> void:
	half_hp_activation = false
	state_machine.Initialize(self)
	wings_animation = $Sprite2D/Wings/WingsAnimation
	animation_player = $Sprite2D/AnimationPlayer
	if wings_animation != null:
		wings_animation.play("Fly")
	animation_player.play("Move")
	player = PlayerManager.player

func _on_fight_began() -> void:
	for ability in stats.initial_ability:
		ability.activate_ability(self)

func _physics_process(_delta: float) -> void:
	move_and_slide()
