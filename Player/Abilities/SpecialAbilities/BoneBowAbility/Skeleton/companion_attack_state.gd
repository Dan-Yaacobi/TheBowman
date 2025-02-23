class_name CompanionAttackingState extends CompanionState

# store a refernece to the player this belongs to
@onready var moving: CompanionMovingState = $"../Moving"

var attack_direction: Vector2

func init() -> void:
	pass
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	companion.velocity = Vector2.ZERO
	companion.update_animation("Attack")
	if not companion.animation_player.animation_finished.is_connected(shoot):
		companion.animation_player.animation_finished.connect(shoot)
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> CompanionState:
	if companion.curr_enemy_att == null:
		return moving
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> CompanionState:
	calculate_direction_to_target()
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> CompanionState:
	return null
	
func set_companion_facing_direction() -> void:
	companion.sprite.flip_h = companion.global_position.x < companion.curr_enemy_att.global_position.x

func calculate_direction_to_target() -> void:
	if companion.curr_enemy_att != null:
		attack_direction = (companion.curr_enemy_att.global_position - companion.global_position).normalized()

func shoot(v) -> void:
	var arm: SkeletonArm = companion.data.projectile.instantiate()
	arm.global_position = companion.global_position
	arm.direction = attack_direction
	arm.damage = randi_range(5,10)
	companion.get_parent().add_child(arm)
	companion.update_animation("Attack")
	pass
