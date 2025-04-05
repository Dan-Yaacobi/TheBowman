class_name DemoEnemyBoss extends Enemy

@onready var ground_detector: Area2D = $GroundDetector
@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var shoot_timer: Timer = $ShootTimer
@onready var hurt_box: Area2D = $HurtBox
@onready var hit_box: Area2D = $HitBox

func _ready() -> void:
	animation_player = $Sprite2D/AnimationPlayer
	scale *= 3
	enemy_state_machine.Initialize(self)
	hit_box.area_entered.connect(hit)
	hurt_box.body_entered.connect(player_hit)
	pass
	
func _physics_process(delta: float) -> void:
	move_and_slide()
	pass

func shoot() -> void:
	if stats.bullet != null and not stunned_state:
		var new_bullet: EnemyBullet = stats.bullet.instantiate()

		new_bullet.scale *= 2
		if stats.shoot_speed != 0:
			shoot_timer.wait_time = min(new_bullet.data.fire_cooldown,stats.shoot_speed)
		else:
			shoot_timer.wait_time = new_bullet.data.fire_cooldown
		new_bullet.direction = calculate_direction_to_player()
		new_bullet.global_position = global_position
		new_bullet.data.knockback = stats.knockback
		new_bullet.data.move_speed = stats.move_speed * 3
		get_parent().add_child(new_bullet)
