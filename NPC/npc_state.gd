class_name NPCState extends Node2D

var npc: NPC
var state_machine: NPCStateMachine

func init() -> void:
	pass
	
func _ready() -> void:
	pass

func Enter() -> void:
	pass
	
func Exit() -> void:
	pass
	
func Process(_delta: float) -> NPCState:
	return null
	
func Physics(_delta: float) -> NPCState:
	return null
	
func HandleInput(_event: InputEvent) -> NPCState:
	return null
	
	
