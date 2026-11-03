class_name PlayerOffHand extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bow_sprite: Sprite2D = $Bow/Sprite2D
@onready var string: Line2D = $String

@onready var bow_top: Node2D = $Bow/BowTop
@onready var bow_bottom: Node2D = $Bow/BowBottom

var string_pull_target: Node2D = null
@export var hold_rotation_offset_degrees: float = 0.0
## In-hand size for bows with fit data. Each bow is scaled so its visible art (mostly width, some height) matches this.
@export var bow_size: float = 31.0

const BOW_WIDTH_WEIGHT: float = 0.65

var default_bow_top: Vector2
var default_bow_bottom: Vector2
var default_bow_offset: Vector2

var position_target: Node2D = null
var rotation_target: Node2D = null
var facing_left: bool = false
func _ready() -> void:
	default_bow_top = bow_top.position
	default_bow_bottom = bow_bottom.position
	default_bow_offset = bow_sprite.offset
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

func hold(hand: Node2D, string_point: Node2D, grip: Node2D) -> void:
	position_target = grip
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
		if _data.string_tip != Vector2.ZERO and _data.texture:
			_fit_bow(_data)
		else:
			bow_sprite.scale = _data.equipped_scale
			bow_sprite.offset = default_bow_offset
			bow_top.position = default_bow_top
			bow_bottom.position = default_bow_bottom
		string.show()
		bow_sprite.show()

## Same size, grip on the hand, string on the tips - for any bow sprite with fit data.
func _fit_bow(_data: EquipmentData) -> void:
	var size: Vector2 = _data.texture.get_size()
	var right_tip: Vector2 = _data.string_tip
	var left_tip: Vector2 = Vector2(size.x - right_tip.x, right_tip.y)
	var bow_scale: float = bow_size / _bow_art_size(_data.texture)
	bow_sprite.scale = Vector2(bow_scale, bow_scale)
	bow_sprite.offset = size / 2.0 - _data.grip_point
	bow_top.position = bow_sprite.transform * (right_tip - _data.grip_point)
	bow_bottom.position = bow_sprite.transform * (left_tip - _data.grip_point)

## Visible art size in pixels: mostly width, some height, so wide and tall bows read about the same size.
func _bow_art_size(texture: Texture2D) -> float:
	var used: Rect2i = texture.get_image().get_used_rect()
	return maxf(pow(used.size.x, BOW_WIDTH_WEIGHT) * pow(used.size.y, 1.0 - BOW_WIDTH_WEIGHT), 1.0)

func hide_bow() -> void:
	string.hide()
	bow_sprite.hide()
