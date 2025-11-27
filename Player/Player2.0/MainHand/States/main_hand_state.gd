class_name MainHandState extends Node

# store a refernece to the player this belongs to
static var entity: PlayerMainHand
static var state_machine: MainHandStateMachine

func init() -> void:
	pass
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> MainHandState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> MainHandState:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> MainHandState:
	return null
	
	
