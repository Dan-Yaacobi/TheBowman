class_name PlayerOffHand extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var off_hand_state_machine: OffHandStateMachine = $OffHandStateMachine
@onready var bow_sprite: Sprite2D = $Bow/Sprite2D
@onready var string: Line2D = $String
@onready var idle: IdleOffHandState = $OffHandStateMachine/Idle

var main_hand: PlayerMainHand
var shoulder: Node2D

func _ready() -> void:
	hide_bow()
	off_hand_state_machine.Initialize(self)
	EventBus.player_died.connect(reset)

func reset(_m: bool) -> void:
	off_hand_state_machine.ChangeState(idle)
	
func _process(_delta: float) -> void:
	pass

func set_new_bow(_data: EquipmentData) -> void:
	if _data:
		bow_sprite.texture = _data.texture
		bow_sprite.scale = _data.equipped_scale
		string.show()
		bow_sprite.show()

func hide_bow() -> void:
	string.hide()
	bow_sprite.hide()
	
func connect_hands(_main_hand: PlayerMainHand, _shoulder: Node2D) -> void:
	main_hand = _main_hand
	shoulder = _shoulder
