class_name DemoEnemy extends Enemy

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

@onready var hit_box: Area2D = $HitBox
@onready var hurt_box: Area2D = $HurtBox

enum directions{TOP_LEFT,TOP_RIGHT,BOTTOM_RIGHT,BOTTOM_LEFT}
var current_direction: directions

var max_hp: int
var boss_phase_II: bool = false

func _ready() -> void:
	if stats.boss:
		scale *= 5
		stats.hp *= 20
		max_hp = stats.hp
		stats.knockback *= 1.2
		stats.move_speed *= 3
		
	animation_player.play("Move")
	hit_box.area_entered.connect(hit)
	hurt_box.body_entered.connect(player_hit)
	sprite.texture = stats.skin
	change_direction()
	for ability in stats.initial_ability:
		ability.activate_ability(self)
	
func _physics_process(delta: float) -> void:
	if stats.boss:
		if not boss_phase_II and stats.hp < max_hp/2:
			boss_upgrade()
			boss_phase_II = true

	direction = calculate_direction_to_player()
	
	if change_direction():
		initial_speed()
		
	if velocity == Vector2.ZERO:
		initial_speed()
		
	activate_debuffs()
	
	if poisoned_state and poisoned_timer != null:
		if poisoned_timer.is_stopped():
			poisoned_timer.start()
	
	if stunned_state and stunned_timer != null:
		velocity = Vector2.ZERO
		if stunned_timer.is_stopped():
			stunned_timer.start()

	velocity  += calculate_direction_to_player() * stats.move_speed * delta
	move_and_slide()
	pass

func change_direction() -> bool:
	if not stats.sharp_movement:
		return false
	var turn: bool = false
	if global_position.x > player.global_position.x:
		if global_position.y > player.global_position.y:
			if current_direction != directions.BOTTOM_RIGHT:
				turn = true
				current_direction = directions.BOTTOM_RIGHT
		else:
			if current_direction != directions.TOP_RIGHT:
				turn = true
				current_direction = directions.TOP_RIGHT
	else:
		if global_position.y > player.global_position.y:
			if current_direction != directions.BOTTOM_LEFT:
				turn = true
				current_direction = directions.BOTTOM_LEFT
		else:
			if current_direction != directions.TOP_LEFT:
				turn = true
				current_direction = directions.TOP_LEFT
	return turn
	
func initial_speed() -> void:
	velocity = calculate_direction_to_player() * stats.move_speed * 2

func boss_upgrade() -> void:
		stats.move_speed *= 1.2
		scale /= 1.5
		stats.knockback *= 2
		var player_x = player.global_position.x
		global_position = player.global_position + Vector2(randi_range(player_x - 100, player_x + 100),-100)
		initial_speed()
