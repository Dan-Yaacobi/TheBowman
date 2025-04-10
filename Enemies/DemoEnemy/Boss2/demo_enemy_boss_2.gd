class_name DemoEnemyBoss2 extends Enemy

@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var shoot_timer: Timer = $ShootTimer
@onready var pre_ability_location: Area2D = $PreAbilityLocation
@onready var hit_box: Area2D = $HitBox
@onready var hurt_box: Area2D = $HurtBox
@onready var wings_animation: AnimationPlayer = $Sprite2D/Wings/WingsAnimation

const MINI_ENEMY = preload("res://Enemies/DemoEnemy/DemoEnemy2.tscn")

func _ready() -> void:
	enemy_state_machine.Initialize(self)
	animation_player = $Sprite2D/AnimationPlayer
	wings_animation.play("Fly")
	scale *= 3
	pre_ability_location.reparent(get_parent())
	hit_box.area_entered.connect(hit)
	hurt_box.body_entered.connect(player_hit)

func _physics_process(delta: float) -> void:
	move_and_slide()
	
func shoot(_direction = null) -> void:
	if stats.bullet != null and not stunned_state:
		if _direction == null:
			_direction = calculate_direction_to_player()
			
		var new_bullet: EnemyBullet = stats.bullet.instantiate()
		new_bullet.scale *= 1.5
		new_bullet.direction = _direction #calculate_direction_to_player()
		new_bullet.global_position = global_position
		new_bullet.data.knockback = stats.knockback
		new_bullet.data.move_speed = stats.move_speed * 3
		get_parent().add_child(new_bullet)

func summon() -> void:
	update_animation("Summon")
	var new_summon: DemoEnemy = MINI_ENEMY.instantiate()
	new_summon.get_player(player)
	new_summon.global_position = global_position + Vector2(
		[1,-1].pick_random() * randi_range(30,50),
		[1,-1].pick_random() * randi_range(30,50))
	get_parent().add_child(new_summon)
	get_parent().summoned_enemies.append(new_summon)
	pass
