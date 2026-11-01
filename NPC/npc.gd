class_name NPC extends Node2D

signal disappear

@onready var npc_state_machine: NPCStateMachine = $NpcStateMachine
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var keyboard_press_helper: KeyBoardHelper = $KeyboardPressHelper

@export var data: NPCData
## Optional. Plays "idle" by default and "talk" while the chat box is typing.
@export var animation_player: AnimationPlayer

var action_taken: bool = false
var facing_direction: int = 1
var chat_box: ChatBox

func face_the_player() -> void:
	if not data.idle:
		var player_x: float = PlayerManager.player.global_position.x
		var dir: int = 1 if player_x > global_position.x else -1
		if dir != facing_direction:
			facing_direction = dir
			sprite.scale.x = dir
	
func _ready() -> void:
	if data.has_chat:
		chat_box = $ChatBox
	_setup_animation()

	npc_state_machine.Initialize(self)
	keyboard_press_helper.set_up()
	extra_ready_functions()
	
func _process(_delta: float) -> void:
	face_the_player()
	extra_process_function(_delta)
	
func _setup_animation() -> void:
	if animation_player == null:
		return
	if chat_box:
		chat_box.typing_started.connect(_play_animation.bind("talk"))
		chat_box.typing_finished.connect(_play_animation.bind("idle"))
	_play_animation("idle")

## Keeps the playback position so shared tracks (e.g. a float) don't snap when switching.
func _play_animation(anim_name: String) -> void:
	if not animation_player.has_animation(anim_name):
		return
	var position_before: float = animation_player.current_animation_position if animation_player.is_playing() else 0.0
	animation_player.play(anim_name)
	var length: float = animation_player.get_animation(anim_name).length
	animation_player.seek(fmod(position_before, length), true)

func extra_process_function(_delta: float) -> void:
	pass
	
func extra_ready_functions() -> void:
	pass
	
func extra_gone_function() -> void:
	pass
	
func action(_index: int) -> void:
	pass

func show_post_action_line() -> void:
	chat_box.show_line(data.post_action_lines.pick_random())

## True keeps the NPC in Interacted after action(0) instead of going straight to Gone.
func holds_interaction() -> bool:
	return false

## Called when the Interacted state exits.
func on_interaction_closed() -> void:
	pass
