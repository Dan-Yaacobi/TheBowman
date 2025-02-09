class_name CompanionState extends Node

# store a refernece to the player this belongs to
var companion: Companion
static var state_machine: CompanionStateMachine

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
func Process(_delta: float) -> CompanionState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> CompanionState:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> CompanionState:
	return null
	
	
