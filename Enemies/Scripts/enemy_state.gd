class_name EnemyState extends Node

#stores reference to the enemy this state belongs to
var enemy: Enemy
var state_machine: EnemyStateMachine

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
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
