class_name SpiderWalkingState extends EnemyState

@onready var walking_sprite: Sprite2D = $"../../WalkingSprite"
@onready var walking_animation: AnimationPlayer = $"../../WalkingSprite/WalkingAnimation"

@onready var raycast: RayCast2D = $"../../RayCast2D_Left"


var direction: int

#what happens when we initialize this state
func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	
	enemy.no_push_back = false
	enemy.animation_player = walking_animation
	enemy.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	walking_sprite.visible = true
	enemy.update_animation("Move")
	if enemy.player.global_position.x > enemy.global_position.x:
		direction = 1
	else:
		direction = -1
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:

	if enemy.velocity.x > 0:
		raycast = $"../../RayCast2D_Right"
	else:
		raycast = $"../../RayCast2D_Left"
		
	if enemy.player.global_position.x > enemy.global_position.x:
		if walking_sprite.flip_h == false:
			enemy.velocity.x = 0
			direction = 1
		walking_sprite.flip_h = true
	else:
		if walking_sprite.flip_h == true:
			enemy.velocity.x = 0
			direction = -1
		walking_sprite.flip_h = false
		
	if not raycast.is_colliding():
		enemy.velocity.x = 0
		enemy.no_push_back = true
	else:
		enemy.no_push_back = false
	if not enemy.is_on_floor():
		enemy.velocity.x = 0
		
	enemy.velocity.x += direction * enemy.stats.move_speed * _delta
	return null
	
func initial_speed() -> void:
	enemy.velocity.x = direction * enemy.stats.move_speed
