class_name NPC extends Node2D

signal disappear

@onready var npc_state_machine: NPCStateMachine = $NpcStateMachine
@onready var chat_box: ChatBox = $ChatBox
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D

@export var data: NPCData

var action_taken: bool = false
var facing_direction: int = 1

func face_the_player() -> void:
	var player_x: float = PlayerManager.player.global_position.x
	var dir: int = 1 if player_x > global_position.x else -1
	if dir != facing_direction:
		facing_direction = dir
		sprite.scale.x = dir
	
func _ready() -> void:
	npc_state_machine.Initialize(self)
	extra_ready_functions()

func _process(_delta: float) -> void:
	face_the_player()
	extra_process_function(_delta)
	
func extra_process_function(_delta: float) -> void:
	pass
	
func extra_ready_functions() -> void:
	pass
	
func action(_index: int) -> void:
	pass

func show_post_action_line() -> void:
	chat_box.show_line(data.post_action_lines.pick_random())
