class_name PlayerOffHand extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var off_hand_state_machine: OffHandStateMachine = $OffHandStateMachine
@onready var bow_sprite: Sprite2D = $Bow/Sprite2D
@onready var string: Line2D = $String

var main_hand: PlayerMainHand
var shoulder: Node2D

func _ready() -> void:
	off_hand_state_machine.Initialize(self)
	pass
	
func _process(_delta: float) -> void:
	pass

func new_bow(weapon_data: WeaponData) -> void:
	string.default_color = weapon_data.string_color
	bow_sprite.texture = weapon_data.sprite
	bow_sprite.position = weapon_data.bow_position
	string.width = weapon_data.string_thickness
	
func connect_hands(_main_hand: PlayerMainHand, _shoulder: Node2D) -> void:
	main_hand = _main_hand
	shoulder = _shoulder
