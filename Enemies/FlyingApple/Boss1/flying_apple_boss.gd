class_name FlyingRedAppleBoss extends Boss

@onready var ground_detector: Area2D = $GroundDetector
@onready var shoot_timer: Timer = $ShootTimer

@onready var wings: Sprite2D = $Sprite2D/Wings

var wings_animation: AnimationPlayer

var player: Player

func extra_ready_functions() -> void:
	scale *= 3
	state_machine.Initialize(self)
	wings_animation  = $Sprite2D/Wings/WingsAnimation
	animation_player = $Sprite2D/AnimationPlayer
	if wings_animation != null:
		wings_animation.play("Fly")
	animation_player.play("Move")
	hurt_box.knockback_power = stats.knockback
	hurt_box.damage = stats.touch_damage
	player = PlayerManager.player
	hit_box.set_enemy(self)
	sprite.texture = stats.skin
	for ability in stats.initial_ability:
		ability.activate_ability(self)
	if boss_health_bar:
		boss_health_bar.init_health(stats.max_hp)
		
func _physics_process(_delta: float) -> void:
	move_and_slide()
		
