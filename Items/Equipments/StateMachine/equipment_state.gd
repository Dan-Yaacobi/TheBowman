class_name EquipmentState extends Node

#stores reference to the enemy this state belongs to
var equipment: Equipment
var state_machine: EquipmentStateMachine

#what happens when we initialize this state
func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EquipmentState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EquipmentState:
	return null
	
