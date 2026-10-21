class_name PlayerOffHand extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bow_sprite: Sprite2D = $Bow/Sprite2D
@onready var string: Line2D = $String

@onready var bow_top: Node2D = $Bow/BowTop
@onready var bow_bottom: Node2D = $Bow/BowBottom

var string_pull_target: Node2D = null
@export var hold_rotation_offset_degrees: float = 0.0

var position_target: Node2D = null
var rotation_target: Node2D = null
var facing_left: bool = false
func _ready() -> void:
	hide_bow()

func _process(_delta: float) -> void:
	process_priority = 1
	if position_target:
		global_position = position_target.global_position
	if rotation_target:
		var offset: float = deg_to_rad(hold_rotation_offset_degrees)
		rotation = rotation_target.rotation + (-offset if facing_left else offset)
	else:
		rotation = PI if facing_left else 0.0
	_update_string()
	
func set_facing(_facing_left: bool) -> void:
	facing_left = _facing_left
	scale.x = absf(scale.x)
	scale.y = -absf(scale.y) if facing_left else absf(scale.y)
	
func rest(shoulder: Node2D) -> void:
	position_target = shoulder
	rotation_target = null
	string_pull_target = null
	z_index = -2

func hold(hand: Node2D, string_point: Node2D) -> void:
	rotation_target = hand
	string_pull_target = string_point
	z_index = 0

func _update_string() -> void:
	var top: Vector2 = string.to_local(bow_top.global_position)
	var bottom: Vector2 = string.to_local(bow_bottom.global_position)
	var middle: Vector2 = (top + bottom) / 2.0
	if string_pull_target:
		middle = string.to_local(string_pull_target.global_position)
	string.points = PackedVector2Array([top, middle, bottom])

func play_stage(stage: String, pull_speed: float) -> void:
	var anim: String = "Idle"
	if stage == "Pull":
		anim = "Pull"
	elif stage == "MaxPull":
		anim = "Max Pull" if animation_player.has_animation("Max Pull") else "Pull"
	if animation_player.assigned_animation == anim:
		return
	animation_player.speed_scale = pull_speed if anim == "Pull" else 1.0
	animation_player.play(anim)

func set_new_bow(_data: EquipmentData) -> void:
	if _data:
		bow_sprite.texture = _data.texture
		bow_sprite.scale = _data.equipped_scale
		string.show()
		bow_sprite.show()

func hide_bow() -> void:
	string.hide()
	bow_sprite.hide()
