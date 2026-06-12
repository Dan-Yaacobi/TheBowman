class_name FlyingRedAppleBoss extends FlyingApple

@onready var ground_detector: Area2D = $GroundDetector
@onready var shoot_timer: Timer = $ShootTimer

var player: Player

func extra_ready_functions() -> void:
	scale *= 3
	state_machine.Initialize(self)
	wings_animation  = $Sprite2D/Wings/WingsAnimation
	animation_player = $Sprite2D/AnimationPlayer
	if wings_animation != null:
		wings_animation.play("Fly")
	animation_player.play("Move")
	player = PlayerManager.player
	hurt_box.knockback_power = stats.knockback
	hurt_box.damage = stats.touch_damage

	hit_box.set_enemy(self)
	sprite.texture = stats.skin
	for ability in stats.initial_ability:
		ability.activate_ability(self)
		
func _physics_process(_delta: float) -> void:
	move_and_slide()
	pass
	
func drop_item() -> void:
	var drop_chance: float = min(
		stats.drop_chance + PlayerManager.player.stats.extra_drop_chance.value(),
		100)
	EventBus.try_drop.emit(global_position, drop_chance)
	EventBus.try_drop.emit(global_position, drop_chance)
	EventBus.try_drop.emit(global_position, drop_chance)
	EventBus.drop_coins.emit(global_position, stats.avg_coins_dropped)
