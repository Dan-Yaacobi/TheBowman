class_name CompanionMovingState extends CompanionState

# store a refernece to the player this belongs to

@onready var attacking: CompanionAttackingState = $"../Attacking"

var raycast: RayCast2D
var direction: int = 1

func init() -> void:
	pass
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:

	companion.update_animation("Move")
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> CompanionState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> CompanionState:
	if companion.curr_enemy_att != null:
		return attacking
	if companion.velocity.x > 0:
		raycast = companion.ray_cast_right
		companion.sprite.flip_h = false
	else:
		raycast = companion.ray_cast_left
		companion.sprite.flip_h = true
		
	if not raycast.is_colliding():
		direction *= -1
	#print("the skeleton: ", companion, " ray ", raycast)
	companion.velocity.x = direction * companion.data.move_speed * _delta
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> CompanionState:
	return null
	
	
