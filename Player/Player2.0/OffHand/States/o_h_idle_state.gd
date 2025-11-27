class_name IdleOffHandState extends OffHandState
@onready var shooting: ShootingOffHandState = $"../Shooting"

# store a refernece to the player this belongs to
func init() -> void:
	pass
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	entity.rotation = 0
	entity.z_index = -2
	entity.animation_player.play("RESET")
	if entity.shoulder != null:
		entity.global_position = entity.shoulder.global_position
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> OffHandState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> OffHandState:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> OffHandState:
	if _event.is_action_pressed("shoot",true):
		return shooting
	return null
	
	
