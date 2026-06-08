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
	enemy.sprite = walking_sprite
	enemy.stats.can_be_knockedback = true
	enemy.animation_player = walking_animation
	enemy.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	walking_sprite.visible = true
	enemy.update_animation("Move")
	direction = [-1, 1].pick_random()
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	# pick raycast based on movement direction
	if direction > 0:
		raycast = $"../../RayCast2D_Right"
	else:
		raycast = $"../../RayCast2D_Left"

	# flip sprite to match direction
	walking_sprite.flip_h = direction > 0

	# reverse direction at edge or if airborne
	if not raycast.is_colliding() or not enemy.is_on_floor():
		direction = -direction
		enemy.velocity.x = 0

	enemy.velocity.x = direction * enemy.stats.move_speed.value()
	return null
	
func initial_speed() -> void:
	enemy.velocity.x = direction * enemy.stats.move_speed.value()
