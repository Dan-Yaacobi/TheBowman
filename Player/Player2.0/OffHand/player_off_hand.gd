class_name PlayerOffHand extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bow_sprite: Sprite2D = $Bow/Sprite2D
@onready var string: Line2D = $String

var position_target: Node2D = null
var rotation_target: Node2D = null

func _ready() -> void:
	hide_bow()

func _process(_delta: float) -> void:
	if position_target:
		global_position = position_target.global_position
	rotation = rotation_target.rotation if rotation_target else 0.0

func rest(shoulder: Node2D) -> void:
	position_target = shoulder
	rotation_target = null
	z_index = -2
	animation_player.speed_scale = 1.0
	animation_player.play("RESET")

func hold(string_point: Node2D, hand: Node2D, pull_speed: float) -> void:
	position_target = string_point
	rotation_target = hand
	z_index = 0
	animation_player.speed_scale = pull_speed
	animation_player.play("Pull")

func set_new_bow(_data: EquipmentData) -> void:
	if _data:
		bow_sprite.texture = _data.texture
		bow_sprite.scale = _data.equipped_scale
		string.show()
		bow_sprite.show()

func hide_bow() -> void:
	string.hide()
	bow_sprite.hide()
